//
//  SessionView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI

struct SessionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var navigationManager = NavigationManager.shared
    @Binding var session: Session
    
    var body: some View {
        VStack {
            title
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
        }
    }
}
