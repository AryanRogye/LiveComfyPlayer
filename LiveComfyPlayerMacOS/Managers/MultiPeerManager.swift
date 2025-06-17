//
//  MultiPeerManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Cocoa

import MultipeerConnectivity
import CryptoKit

struct PeerMessage: Codable {
    let type: PeerMessageType
    let payload: String
}

enum PeerMessageType: String, Codable {
    case roomKey
    case roomKeyResponse
    case status
    case unknown
}

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
    
    @Published var verifiedPeers: [MCPeerID] = []
    
    @Published public var roomKey: String?
    
    
    public func start(session userSession: Session) {
        print("Called MultiPeerManager.start()")
        if self.peerID == nil {
            var displayName = "\(authManager.fullName ?? "Unknown User") | \(userSession.name)"
            /// Make Sure DisplayName doesnt exceed 76 Characters
            if displayName.count > 76 { displayName = String(displayName.prefix(76)) }
            self.peerID = MCPeerID(displayName: displayName)
        }
        guard let peerID = self.peerID else {
            print("❌ Could not create peerID.")
            return
        }
        
        guard advertiser == nil else {
            print("⚠️ Already advertising.")
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
    
    internal func handleIncomingData(_ data: Data, from peer: MCPeerID) throws {
        let message = try JSONDecoder().decode(PeerMessage.self, from: data)
        
        switch message.type {
        case .roomKey:          handleRoomKeyResponse(message.payload, from: peer)
        case .roomKeyResponse:  print("Received room key response from \(peer.displayName): \(message.payload)")
        case .status:           print("Received status from \(peer.displayName): \(message.payload)")
        case .unknown:          print("Received unknown message type from \(peer.displayName): \(message.payload)")
        }
    }
    
    public func handleRoomKeyResponse(_ response: String, from peer: MCPeerID) {
        // Handle the room key response from the peer
        print("Received room key response from \(peer.displayName): \(response)")
        
        // You can add logic here to verify the response or update UI
        let answer = response == roomKey ? "1" : "0"
        send(.roomKeyResponse, payload: answer, to: peer) { success in
            if success {
                print("✅ Successfully sent room key response to \(peer.displayName)")
            } else {
                print("❌ Failed to send room key response to \(peer.displayName)")
            }
        }
        
        if response == roomKey {
            DispatchQueue.main.async {
                if !self.verifiedPeers.contains(peer) {
                    self.verifiedPeers.append(peer)
                    print("✅ Peer \(peer.displayName) verified with room key.")
                }
            }
        }
    }
    
    private func send(_ type: PeerMessageType, payload: String, to peer: MCPeerID, success: @escaping (Bool) -> Void) {
        guard let session = session else {
            print("❌ No session.")
            success(false)
            return
        }
        
        guard connectedPeers.contains(peer) else {
            print("❌ Peer not connected.")
            success(false)
            return
        }
        
        do {
            let message = PeerMessage(type: type, payload: payload)
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("📤 Sent \(type.rawValue) to \(peer.displayName)")
            success(true)
        } catch {
            print("❌ Failed to send: \(error.localizedDescription)")
            success(false)
        }
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
                self.verifiedPeers.removeAll { $0 == peerID }
            case .connecting:
                print("🔄 Connecting to \(peerID.displayName)...")
            case .connected:
                print("✅ Connected to \(peerID.displayName)")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            @unknown default:
                print("🌀 Unknown state from \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 📦 handle incoming messages
        do {
            try handleIncomingData(data, from: peerID)
        } catch {
            print("❌ Failed to decode incoming data: \(error.localizedDescription)")
        }
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


extension MultiPeerManager {
    public func generateRoomKey(_ session: Session) {
        let input = "\(session.name)\(Date().timeIntervalSince1970)"
        let hash = SHA256.hash(data: Data(input.utf8))
        
        // Take first 4 bytes and convert to UInt32
        let keyBytes = hash.prefix(4)
        let keyInt = keyBytes.reduce(0) { ($0 << 8) | UInt32($1) }
        
        // Limit it to a 6-digit number
        roomKey = String(keyInt % 1_000_000)
    }
    public func clearRoomKey() {
        roomKey = nil
    }
}
