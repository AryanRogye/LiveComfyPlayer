//
//  ContentView.swift
//  LiveComfyPlayeriOS
//
//  Created by Aryan Rogye on 6/17/25.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    
    @ObservedObject private var navigationManager = NavigationManager.shared
    @ObservedObject private var sessionManager = SessionManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var showSignInSheet: Bool = true
    
    var body: some View {
        ZStack {
            if let id = navigationManager.activeSessionID, let index = sessionManager.sessions.firstIndex(where: { $0.id == id }) {
                NavigationStack {
                    SessionView(session: $sessionManager.sessions[index])
                }
            } else {
                TabView {
                    NavigationStack {
                        HomeView()
                    }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
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


#Preview {
    ContentView()
}
