//
//  HomeView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/13/25.
//

import SwiftUI

struct HomeView: View {
    
    @State private var showAddButton: Bool = false
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    var body: some View {
        VStack {
            if showAddButton {
                addVideos
            } else {
                videoList
            }
        }
        .navigationTitle("Home")
        .background(.ultraThinMaterial)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showAddButton.toggle() }) {
                    /// Add Button
                    Image(systemName: !showAddButton ? "plus" : "minus")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .onChange(of: showAddButton) { _, newValue in
            /// Wanna Make the Device Discoverable for the iOS version
            if newValue {
                mpManager.start()
            } else {
                mpManager.stop()
            }
        }
    }
    
    /// Start Showing Main Adding Content In Here
    private var addVideos: some View {
        VStack {
            
        }
    }
    
    /// Start Will Be Nothing
    private var videoList: some View {
        VStack {
            
        }
    }
}
