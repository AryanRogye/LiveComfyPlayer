//
//  Session.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/17/25.
//

import UIKit

class Session: ObservableObject, Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    
    var name: String
    var createdAt: Date
    var videoPaths: [Clip]
    @Published var timelinePaths: [Clip] = []
    
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(videoPaths, forKey: .videoPaths)
        try container.encode(timelinePaths, forKey: .timelinePaths)
    }
    
    static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.createdAt == rhs.createdAt &&
        lhs.videoPaths == rhs.videoPaths &&
        lhs.timelinePaths == rhs.timelinePaths
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(createdAt)
        hasher.combine(videoPaths)
        hasher.combine(timelinePaths)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        videoPaths = try container.decodeIfPresent([Clip].self, forKey: .videoPaths) ?? []
        timelinePaths = try container.decodeIfPresent([Clip].self, forKey: .timelinePaths) ?? []
    }
}
