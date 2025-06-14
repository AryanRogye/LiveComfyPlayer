//
//  MultiPeerManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import Foundation
import MultipeerConnectivity

@MainActor
final class MultiPeerManager: NSObject, ObservableObject {
    static let shared = MultiPeerManager()
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    
    public func startBrowsing() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: "livecomfy-vp")
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("🔍 iOS is now browsing for peers.")
    }
    
    public func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
    }
}

extension MultiPeerManager: @preconcurrency MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("📡 Found peer: \(peerID.displayName)")
        
        if !discoveredPeers.contains(peerID) {
            discoveredPeers.append(peerID)
        }
        
        // Send an invite to connect
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("💨 Lost peer: \(peerID.displayName)")
        discoveredPeers.removeAll { $0 == peerID }
    }
}

extension MultiPeerManager: @preconcurrency MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
    }
}
