//
//  SessionView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import MultipeerConnectivity
import SwiftUI

struct SessionView: View {
    
    var peer: MCPeerID
    var sessionKey: String
    
    @ObservedObject private var globalOverlayManager: GlobalOverlayManager = .shared
    @ObservedObject private var mpManager: MultiPeerManager = .shared

    var body: some View {
        VStack {
            Text("Session View")
            
            Spacer()
            
            Button(action: {
                mpManager.stopBrowsing()
                globalOverlayManager.clear()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
            }
        }
    }
}
