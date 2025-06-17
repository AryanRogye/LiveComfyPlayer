//
//  ContentView.swift
//  LiveComfyPlayeriOS
//
//  Created by Aryan Rogye on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var navigationManager = NavigationManager.shared
    @ObservedObject private var sessionManager = SessionManager.shared
    
    var body: some View {
        NavigationStack {
            if let id = navigationManager.activeSessionID, let index = sessionManager.sessions.firstIndex(where: { $0.id == id }) {
                SessionView(session: $sessionManager.sessions[index])
            } else {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
