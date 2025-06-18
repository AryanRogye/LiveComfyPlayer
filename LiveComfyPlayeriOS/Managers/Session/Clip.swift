//
//  Clip.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/17/25.
//

import Foundation

struct Clip: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let url: URL
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
    }
}
