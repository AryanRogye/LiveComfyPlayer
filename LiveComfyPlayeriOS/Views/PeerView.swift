//
//  PeerView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI
import MultipeerConnectivity

struct PeerView: View {
    var peer: MCPeerID
    
    var body: some View {
        VStack {
            Text(peer.displayName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
