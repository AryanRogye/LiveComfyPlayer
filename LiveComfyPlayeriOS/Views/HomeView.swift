//
//  HomeView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI

struct HomeView: View {
    
    @State private var isScanning = false
    
    var body: some View {
        VStack {
            Text("Home View")
        }
        .sheet(isPresented: $isScanning) {
            NavigationStack {
                MultiPeerScanModal(isScanning: $isScanning)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                scanButton
            }
        }
    }
    
    private var scanButton: some View {
        Button(action: {
            isScanning = true
        }) {
            Image(systemName: "dot.radiowaves.left.and.right")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
