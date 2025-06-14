//
//  MultiPeerScanModal.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI

struct MultiPeerScanModal: View {
    
    @Binding var isScanning: Bool
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(mpManager.discoveredPeers, id: \.self) { peer in
                    DiscoveredPeerItem(peer: peer)
                }
            }
            Spacer()
            closeButton
        }
        .onAppear {
            mpManager.startBrowsing()
        }
        .onDisappear {
            mpManager.stopBrowsing()
        }
    }
    
    private var closeButton: some View {
        Button(action: {
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
