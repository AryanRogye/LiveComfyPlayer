//
//  SessionManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Cocoa


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
    var videoPaths: [URL] // or your own `Video` model later
    
    init(name: String, videoPaths: [URL] = []) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.videoPaths = videoPaths
    }
}
