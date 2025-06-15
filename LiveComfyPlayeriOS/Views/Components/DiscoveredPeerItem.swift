//
//  DiscoveredPeerItem.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI
import MultipeerConnectivity

struct DiscoveredPeerItem: View {
    
    var peer: MCPeerID
    @Binding var isScanning: Bool
    
    var body: some View {
        NavigationLink(destination: PeerView(peer: peer, isScanning: $isScanning)) {
            HStack {
                Text(peer.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
    }
}
