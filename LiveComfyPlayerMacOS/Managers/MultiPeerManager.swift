//
//  MultiPeerManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Cocoa
import MultipeerConnectivity

@MainActor
final class MultiPeerManager: NSObject, ObservableObject {
    static let shared = MultiPeerManager()
    
    private let authManager: AuthManager = .shared
    
    /// represents identity during the entire session
    private var peerID: MCPeerID?
    /// It's what iOS devices detect when scanning
    private var advertiser: MCNearbyServiceAdvertiser?
    /// It's where you receive messages
    /// It keeps track of connected peers
    /// It’s used in the invitationHandler when accepting a peer
    private var session: MCSession?
    /// Connected peers list
    @Published var connectedPeers: [MCPeerID] = []
    
    public func start() {
        print("Called MultiPeerManager.start()")
        if self.peerID == nil {
            self.peerID = MCPeerID(displayName: "\(authManager.fullName ?? "Unknown User")")
        }
        guard let peerID = self.peerID else {
            print("❌ Could not create peerID.")
            return
        }
        
        /// Create A Session
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self
        
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: "livecomfy-vp"
        )
        advertiser?.delegate = self
        self.advertiser?.startAdvertisingPeer()
        
        print("MultiPeerManager started with peer: \(peerID.displayName)")
    }
    
    public func stop() {
        session?.disconnect()
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session = nil
        peerID = nil
        connectedPeers.removeAll()
        print("MultiPeerManager stopped.")
    }
}

extension MultiPeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accept invitations from peers
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising peer: \(error.localizedDescription)")
    }
}

extension MultiPeerManager: @preconcurrency MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // 🧠 handle connect/disconnect
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                print("❌ Disconnected from \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }
            case .connecting:
                print("🔄 Connecting to \(peerID.displayName)...")
            case .connected:
                print("✅ Connected to \(peerID.displayName)")
                self.connectedPeers.append(peerID)
            @unknown default:
                print("🌀 Unknown state from \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 📦 handle incoming messages
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Optional: For live media streams
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Optional: For file transfers
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Optional: File received
    }
}
