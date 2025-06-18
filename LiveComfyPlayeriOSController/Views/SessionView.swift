//
//  SessionView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import MultipeerConnectivity
import SwiftUI

struct SessionView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var peer: MCPeerID
    var sessionKey: String
    
    @ObservedObject private var globalOverlayManager: GlobalOverlayManager = .shared
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    
    private var session: Session? {
        if let sesh = mpManager.macSession {
            return sesh
        }
        return nil
    }

    var body: some View {
        ZStack {
            colorScheme == .dark
                ? Color(red: 18/255, green: 18/255, blue: 18/255).ignoresSafeArea()
                : Color.white.ignoresSafeArea()
            
            VStack {
                title
                ScrollView {
                    sessionView
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var sessionView: some View {
        VStack {
            if let session = session {
                Text("Video Paths")
                ScrollView {
                    ForEach(session.videoPaths) { video in
                        Text("\(video.url)")
                    }
                }
                
                Divider()
                    .padding()
                
                Text("Timeline Paths")
                ScrollView {
                    ForEach(session.timelinePaths) { video in
                        Text("\(video.url)")
                    }
                }
            }
        }
    }
    
    private var close: some View {
        Button(action: {
            mpManager.stopBrowsing()
            globalOverlayManager.clear()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.primary)
        }
    }
    
    private var title: some View {
        HStack {
            VStack {
                HStack {
                    Text(peer.displayName)
                        .font(.title3)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Key: \(sessionKey)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            close
        }
        .padding()
    }
}
