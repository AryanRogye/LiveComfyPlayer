//
//  ContentView.swift
//  LiveComfyPlayerMacOS
//
//  Created by Aryan Rogye on 6/13/25.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    
    enum Tab: String, CaseIterable, Hashable {
        case home = "Home"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .settings: return "gear"
            }
        }
    }
    
    @State private var selectedTab: Tab? = .home
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showSignInSheet: Bool = true
    
    var body: some View {
        // Constrained panel
        ZStack {
            NavigationSplitView {
                List(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                    }
                }
                
            } detail: {
                switch selectedTab {
                case .home: HomeView()
                case .settings: SettingsView()
                case .none: Text("Select a tab")
                }
            }
            .navigationSplitViewStyle(.prominentDetail)
        }
        .onChange(of: authManager.isUserSignedIn) { _, newValue in
            showSignInSheet = !newValue
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInWithAppleView()
        }
    }
}

struct SignInWithAppleView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Sign In with Apple")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            Text("We'll use your Apple ID to create your account securely.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            
            SignInWithAppleButton(.signIn, onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            }, onCompletion: { result in
                switch result {
                case .success(let auth):
                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                        // Just log what we get
                        print("✅ Signed in with userID: \(credential.user)")
                        print("📧 Email: \(credential.email ?? "nil")")
                        print("👤 Name: \(credential.fullName?.formatted() ?? "nil")")
                        
                        AuthManager.shared.handleUserCredentials(credential)
                    }
                case .failure(let failure):
                    print("❌ Sign in failed: \(failure.localizedDescription)")
                    AuthManager.shared.isUserSignedIn = false
                }
            })
            .frame(width: 240, height: 45)
            .padding(.bottom, 16)
        }
        .padding(40)
        .frame(minWidth: 360)
    }
}
