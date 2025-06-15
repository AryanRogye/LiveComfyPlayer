//
//  OverlayManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Foundation
import MultipeerConnectivity

final class GlobalOverlayManager: ObservableObject {
    static let shared = GlobalOverlayManager()
    
    @Published var showSessionView: Bool = false
    
    var selectedPeer: MCPeerID?
    var sessionKey: String?
    
    func show(_ peer: MCPeerID, sessionKey: String) {
        selectedPeer = peer
        self.sessionKey = sessionKey
        showSessionView = true
    }
    
    func clear() {
        selectedPeer = nil
        sessionKey = nil
        showSessionView = false
    }
}
