//
//  MultiPeerScanModal.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI
import MultipeerConnectivity

struct MultiPeerScanModal: View {
    
    @State private var selectedPeer: MCPeerID?
    @Binding var isScanning: Bool
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    ForEach(mpManager.discoveredPeers, id: \.self) { peer in
                        DiscoveredPeerItem(peer: peer, isScanning: $isScanning, selectedPeer: $selectedPeer)
                    }
                }
                Spacer()
                closeButton
            }
            .navigationDestination(item: $selectedPeer) { peer in
                PeerView(peer: peer, isScanning: $isScanning)
            }
            .navigationTitle("Discovered Peers")
        }
        .onAppear {
            mpManager.startBrowsing()
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            mpManager.stopBrowsing()
            isScanning = false
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .clipShape(Circle())
    }
}
