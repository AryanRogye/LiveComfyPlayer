//
//  MultiPeerManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Foundation
import MultipeerConnectivity

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
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var failedVerification: MCPeerID?
    
    private var pendingConnection: (peer: MCPeerID, completion: (Bool) -> Void)?
    private var keyResponseHandlers: [MCPeerID: (Bool) -> Void] = [:]
    
    public func startBrowsing() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: "livecomfy-vp")
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("🔍 iOS is now browsing for peers.")
    }
    
    public func connect(to peer: MCPeerID, success: @escaping (Bool) -> Void) {
        guard let session = session else {
            success(false)
            return
        }
        
        pendingConnection = (peer, success)
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 10)
        print("📨 Sent invite to \(peer.displayName)")
    }
    
    public func sendKey(_ key: String, to peer: MCPeerID, success: @escaping (Bool) -> Void) {
        guard let _ = session else {
            print("❌ Session is not initialized.")
            success(false)
            return
        }
        
        guard connectedPeers.contains(peer) else {
            print("❌ Peer is not connected.")
            success(false)
            return
        }
        keyResponseHandlers[peer] = success
        
        self.send(.roomKey, payload: key, to: peer) { sent in
            if !sent {
                self.keyResponseHandlers.removeValue(forKey: peer)
                success(false)
            }
        }
    }
    
    public func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
    }
    
    internal func handleIncomingData(_ data: Data, from peer: MCPeerID) throws {
        let message = try JSONDecoder().decode(PeerMessage.self, from: data)
        
        switch message.type {
        case .roomKey:          print("Received room key from \(peer.displayName): \(message.payload)")
        case .roomKeyResponse:  handleRoomKeyResponse(message.payload, from: peer)
        case .status:           print("Received status from \(peer.displayName): \(message.payload)")
        case .unknown:          print("Received unknown message type from \(peer.displayName): \(message.payload)")
        }
    }
    
    public func handleRoomKeyResponse(_ response: String, from peer: MCPeerID) {
        print("Recieved Response \(response)")
        let isValid = response == "1"
        if let callback = keyResponseHandlers.removeValue(forKey: peer) {
            callback(isValid)
        }
        
        if isValid {
            
        } else {
            print("❌ Room key rejected by macOS from \(peer.displayName)")
            DispatchQueue.main.async {
                self.failedVerification = peer
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

extension MultiPeerManager: @preconcurrency MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("📡 Found peer: \(peerID.displayName)")
        
        if !discoveredPeers.contains(peerID) {
            discoveredPeers.append(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("💨 Lost peer: \(peerID.displayName)")
        discoveredPeers.removeAll { $0 == peerID }
    }
}

extension MultiPeerManager: @preconcurrency MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("🔄 Peer \(peerID.displayName) changed state: \(state.rawValue)")
        
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if self.connectedPeers.contains(peerID) == false {
                    self.connectedPeers.append(peerID)
                }
                if self.pendingConnection?.peer == peerID {
                    self.pendingConnection?.completion(true)
                    self.pendingConnection = nil
                }
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.pendingConnection?.peer == peerID {
                    self.pendingConnection?.completion(false)
                    self.pendingConnection = nil
                }
                
            default:
                break
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
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
    }
}
