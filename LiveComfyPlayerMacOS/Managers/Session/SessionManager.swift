//
//  SessionManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Cocoa
import Combine

@MainActor
final class SessionManager: ObservableObject {
    private let storageKey = "saved_sessions"
    
    @Published var sessions: [Session] = []
    @Published var player: AVPlayer = AVPlayer()
    
    internal var mpManager = MultiPeerManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSessions()
        observeTimelineChanges()
    }
    
    internal var isUpdatingPeers: Bool = false
    
    private func observeTimelineChanges() {
        cancellables.removeAll()
        sessions.forEach { observe($0) }
    }
    
    private func observe(_ session: Session) {
        session.$timelinePaths
            .sink { [weak self] newPaths in
                Task {
                    await self?.processTimelinePaths(for: session, timeline: newPaths)
                }
                self?.updatePeers(for: session)
            }
            .store(in: &cancellables)
        
        session.$videoPaths
            .sink { [weak self] _ in
                self?.updatePeers(for: session)
            }
            .store(in: &cancellables)
    }
    
    func addSession(_ session: Session) {
        sessions.append(session)
        observeTimelineChanges()
        saveSessions()
    }
    
    func removeSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        observeTimelineChanges()
        saveSessions()
    }
    
    func addVideoPath(_ path: URL, to session: Session) {
        /// Find the index that holds the session
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        let clip = Clip(url: path)
        /// Then add it to it
        sessions[index].videoPaths.append(clip)
        /// Save it
        saveSessions()
    }
    
    func removeVideoFromSession(_ path: URL, from session: Session, success: @escaping (Bool) -> Void) {
        /// Find the index that holds the session
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            success(false)
            return
        }
        
        /// Make Sure the timelinePaths doesnt contain the clip or else return early
        guard !sessions[index].timelinePaths.contains(where: { $0.url == path }) else {
            print("❌ Cannot remove video from session, it is already in the timeline.")
            success(false)
            return
        }
        /// Remove the clip from videoPaths
        sessions[index].videoPaths.removeAll { $0.url == path }
        /// Save it
        saveSessions()
        success(true)
    }
    
    // MARK: - Timeline Management
    func addVideoToTimeline(_ path: URL, for session: Session) {
        /// Find the index that holds the session
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        /// Then add it to the timelinePaths
        let clip = Clip(url: path)
        /// Create a new TimelineClip and append it
        sessions[index].timelinePaths.append(clip)
        /// Save it
        saveSessions()
    }
    
    func removeTimelineClip(_ clip: Clip, from session: Session) {
        /// Find the index that holds the session
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        /// Remove the clip from timelinePaths
        sessions[index].timelinePaths.removeAll { $0.id == clip.id }
        /// Save it
        saveSessions()
    }
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save sessions:", error)
        }
    }
    
    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            sessions = try JSONDecoder().decode([Session].self, from: data)
        } catch {
            print("❌ Failed to load sessions:", error)
        }
    }
    
}

extension SessionManager {
    internal func updatePeers(for session: Session) {
        if isUpdatingPeers { return }
        isUpdatingPeers = true
        defer { isUpdatingPeers = false }
        
        if let mpSession = mpManager.userSession, session.id == mpSession.id {
            mpManager.updatePeersWithSession(session)
        } else {
            print("❌ Session ID mismatch with MultiPeerManager.")
        }
    }
}

import AVFoundation
import AVKit

extension SessionManager {
    internal func processTimelinePaths(for session: Session, timeline: [Clip]) async {
        
        /// Get All The AVURLAssets from the timeline clips
        let assets : [AVURLAsset] = timeline.map { clip in
            AVURLAsset(url: clip.url)
        }
        
        /// Intialize an AVMutableComposition
        let composition = AVMutableComposition()
        
        guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("❌ Failed to add video track to composition.")
            return
        }
        guard let audio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("❌ Failed to add audio track to composition.")
            return
        }
        
        // Get currentTime for all the video clips
        var currentTime: CMTime = .zero
        for asset in assets {
            do {
                guard let assetTrack = try await asset.loadTracks(withMediaType: .video).first else {
                    continue
                }
                
                let timeRange = try await CMTimeRange(start: .zero, duration: asset.load(.duration))
                
                try track.insertTimeRange(timeRange, of: assetTrack, at: currentTime)
                if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                    try audio.insertTimeRange(timeRange, of: audioTrack, at: currentTime)
                }
                
                currentTime = try await currentTime + asset.load(.duration)
            } catch {
                print("❌ Failed to process asset \(asset.url): \(error.localizedDescription)")
                continue
            }
        }
        
        /// Composition is ready
        let playerItem = AVPlayerItem(asset: composition)
        self.player = AVPlayer(playerItem: playerItem)
    }
}
