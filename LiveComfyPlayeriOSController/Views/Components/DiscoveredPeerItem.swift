//
//  DiscoveredPeerItem.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI
import MultipeerConnectivity

extension MCPeerID: Identifiable {
    public var id: String { displayName }
}

struct DiscoveredPeerItem: View {
    var peer: MCPeerID
    @Binding var isScanning: Bool
    @Binding var selectedPeer: MCPeerID?

    @State private var isConnecting: Bool = false
    @State private var showConnectionError: Bool = false
    
    @ObservedObject var mpManager = MultiPeerManager.shared
    
    var body: some View {
        Button(action: {
            isConnecting = true
            mpManager.connect(to: peer) { success in
                isConnecting = false
                if success {
                    selectedPeer = peer        // ← triggers navigation
                } else {
                    showConnectionError = true
                }
            }
        }) {
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
        .buttonStyle(.plain)
        .alert("Failed to connect to \(peer.displayName)", isPresented: $showConnectionError) {
            Button("OK", role: .cancel) {}
        }
    }
}
