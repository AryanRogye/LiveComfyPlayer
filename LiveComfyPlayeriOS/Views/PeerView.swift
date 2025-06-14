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
    
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    
    @State private var key : String = ""
    @State private var isError: Bool = false
    @State private var isConnected: Bool = false
    
    @State private var couldntSend: Bool = false
    @State private var authenticationVerified: Bool = false
    
    var body: some View {
        VStack {
            title
            keyTextField
                .disabled(!isConnected)
            
            Spacer()
        }
        .onAppear {
            mpManager.connect(to: peer) { success in
                isConnected = success
            }
        }
        .onChange(of: isError) { _, newValue in
            if newValue {
                // Show an error alert if the key is invalid
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isError = false
                }
            }
        }
    }
    
    private var title: some View {
        VStack {
            HStack {
                Text(peer.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                    .padding(.leading, 5)
                Spacer()
            }
            if authenticationVerified {
                HStack {
                    Text("Verified By: \(peer.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private var keyTextField: some View {
        VStack {
            HStack {
                TextField("Enter Key", text: $key)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isError ? Color.red : Color.blue.opacity(0.4), lineWidth: 1)
                    )
                    .onChange(of: key) { _, newValue in
                        key = String(newValue.prefix(6).filter { $0.isNumber })
                    }
                    .onChange(of: couldntSend) { _, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                couldntSend = false
                            }
                        }
                    }
                
                Button(action: {
                    mpManager.sendKey(key, to: peer) { success in
                        /// No Matter What Clear Past Values
                        authenticationVerified = false
                        couldntSend = false
                        if success {
                            couldntSend = false
                            authenticationVerified = true
                            key = ""
                        } else {
                            couldntSend = true
                        }
                    }
                }) {
                    Text("Check")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            if couldntSend {
                Text("Couldn't send the key to the peer.")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 2)
                    .animation(.interactiveSpring, value: couldntSend)
            }
        }
    }
}
