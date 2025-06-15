//
//  SessionView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI
import CryptoKit

struct SessionView: View {
    
    @ObservedObject private var authManager: AuthManager = .shared
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    @ObservedObject private var navigationManager = NavigationManager.shared
    
    @Binding var session: Session
    
    @State private var beginMultiPeerSession: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            title
            
            Divider()
                .padding(.horizontal, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            /// Stop the MultiPeer session when the view disappears
            mpManager.stop()
        }
        .onChange(of: beginMultiPeerSession) { _, newValue in
            /// Wanna Make the Device Discoverable for the iOS version
            if newValue {
                mpManager.start(session: session)
                mpManager.generateRoomKey(session)
            } else {
                mpManager.stop()
                mpManager.clearRoomKey()
            }
        }
        
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                if let key = mpManager.roomKey {
                    Text("Room Key: \(key)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    Text("Please start the session to generate a room key")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    beginMultiPeerSession.toggle()
                }) {
                    Image(systemName: beginMultiPeerSession ? "stop.circle" : "play.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    navigationManager.activeSessionID = nil
                    navigationManager.selectedTab = .home
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var title: some View {
        HStack {
            Text("\(session.name)")
                .font(.largeTitle)
                .padding()
            Spacer()
            
            if mpManager.verifiedPeers.count > 0 {
                Text("Verified Users: \(mpManager.verifiedPeers.count)")
                    .font(.caption)
            }
        }
        .padding()
    }
}


#Preview {
    SessionView(session: .constant(Session(name: "hello", videoPaths: [])))
}
