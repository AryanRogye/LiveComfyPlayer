//
//  SettingsView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/13/25.
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @ObservedObject private var auth = AuthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // SECTION: Header
            Text("Account")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 6) {
                LabeledSetting(title: "Name", value: auth.fullName ?? "Unknown")
                LabeledSetting(title: "Email", value: auth.email ?? "Unavailable")
                LabeledSetting(title: "User ID", value: auth.userID ?? "Unavailable", font: .footnote)
            }
            
            Divider().padding(.vertical, 8)
            
            // SECTION: Sign Out Button
            Button {
                auth.signOut()
            } label: {
                Text("Sign Out")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            Spacer()
        }
        .padding(32)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Helper View
struct LabeledSetting: View {
    let title: String
    let value: String
    var font: Font = .body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(font)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }
}
