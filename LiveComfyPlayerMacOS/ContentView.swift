//
//  ContentView.swift
//  LiveComfyPlayerMacOS
//
//  Created by Aryan Rogye on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var navigationManager = NavigationManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var showSignInSheet: Bool = true
    
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        // Constrained panel
        ZStack {
            NavigationStack {
                if let id = navigationManager.activeSessionID, let index = sessionManager.sessions.firstIndex(where: { $0.id == id }) {
                    SessionView(session: $sessionManager.sessions[index]).environmentObject(sessionManager)
                } else {
                    NavigationSplitView {
                        List(selection: $navigationManager.selectedTab) {
                            ForEach(NavigationManager.Tab.allCases, id: \.self) { tab in
                                Label(tab.rawValue, systemImage: tab.icon)
                            }
                        }
                    } detail: {
                        switch navigationManager.selectedTab {
                        case .home: HomeView().environmentObject(sessionManager)
                        case .settings: SettingsView()
                        case .none: Text("Select a tab")
                        }
                    }
                    .navigationSplitViewStyle(.prominentDetail)
                }
            }
        }
        .onChange(of: authManager.isUserSignedIn) { _, newValue in
            showSignInSheet = !newValue
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInWithAppleView()
        }
    }
}
