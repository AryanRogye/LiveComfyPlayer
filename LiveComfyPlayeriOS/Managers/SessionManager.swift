//
//  SessionManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Foundation

final class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var sessions: [Session] = []
    private let storageKey = "saved_sessions"
    
    private init() {
        loadSessions()
    }
    
    func addSession(_ session: Session) {
        sessions.append(session)
        saveSessions()
    }
    
    func removeSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
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

struct Session: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var createdAt: Date
    var videoPaths: [Clip]
    var timelinePaths: [Clip]
    
    init(name: String, videoPaths: [Clip] = []) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.videoPaths = videoPaths
        self.timelinePaths = []
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, videoPaths, timelinePaths
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        videoPaths = try container.decodeIfPresent([Clip].self, forKey: .videoPaths) ?? []
        timelinePaths = try container.decodeIfPresent([Clip].self, forKey: .timelinePaths) ?? []
    }
}

struct Clip: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let url: URL
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
    }
}
