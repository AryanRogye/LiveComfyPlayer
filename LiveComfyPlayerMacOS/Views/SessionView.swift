//
//  SessionView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

import SwiftUI

struct SessionView: View {
    
    @ObservedObject private var authManager: AuthManager = .shared
    @ObservedObject private var mpManager: MultiPeerManager = .shared
    @ObservedObject private var navigationManager = NavigationManager.shared
    
    @Binding var session: Session
    @State private var beginMultiPeerSession: Bool = false
    @State private var showVerifiedUsers = false
    
    @State private var topHeight: CGFloat = 200
    
    let screenSize = NSScreen.main?.frame.size ?? .zero

    var body: some View {
        VStack(spacing: 0) {
            title
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    MediaBrowserView(session: $session)
                        .frame(height: topHeight)
                    
                    draggableDivider(geometry: geometry)
                    
                    MediaTimelineView(session: $session)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth:  screenSize.width  * 0.7, maxWidth:  .infinity,
               minHeight: screenSize.height * 0.7, maxHeight: .infinity)
        
        .onDisappear {
            /// Stop the MultiPeer session when the view disappears
            mpManager.stop()
        }
        .onChange(of: beginMultiPeerSession) { _, newValue in
            /// Wanna Make the Device Discoverable for the iOS version
            if newValue {
                mpManager.start(session: session)
                mpManager.generateRoomKey(session)
            } else {
                mpManager.stop()
                mpManager.clearRoomKey()
            }
        }
        
        .toolbar {
            // MARK: - Room Key
            ToolbarItem(placement: .secondaryAction) {
                if let key = mpManager.roomKey {
                    Text("Room Key: \(key)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    Text("Please start the session to generate a room key")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            // MARK: - Toggle MultiPeer Connectivity
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    beginMultiPeerSession.toggle()
                }) {
                    Image(systemName: beginMultiPeerSession ? "stop.circle" : "play.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            // MARK: - Close
            ToolbarItem(placement: .navigation) {
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
    
    private func draggableDivider(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(height: 2)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let newHeight = topHeight + value.translation.height
                        if newHeight > 100 && newHeight < geometry.size.height - 100 {
                            topHeight = newHeight
                        }
                    }
            )
            .background(Color.clear)
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
    
    // MARK: - Title
    private var title: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(session.name)")
                    .font(.title3)
                    .padding([.horizontal])
                    .padding([.top, .bottom], 5)
                Spacer()
            }
            
            if mpManager.verifiedPeers.count > 0 {
                /// Show The Name In A DropDown
                verifiedUsersDropdown
                    .padding(.bottom, 2)
            }

            Divider()
                .padding(.horizontal, 8)

        }
        .padding(.horizontal)
    }
    
    let backgroundColor = Color(NSColor.controlBackgroundColor)
    let borderColor = Color(NSColor.separatorColor)
    
    // MARK: - Verified Users
    private var verifiedUsersDropdown: some View {
        DisclosureGroup(isExpanded: $showVerifiedUsers) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(mpManager.verifiedPeers, id: \.self) { peer in
                    HStack {
                        Text(peer.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onHover { isHovered in
                        // Optional: Add hover effect if needed
                    }
                }
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderColor, lineWidth: 0.5)
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 10))
                Text("Verified (\(mpManager.verifiedPeers.count))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .accentColor(.primary)
        .padding(.bottom, 5)
    }
}


#Preview {
    SessionView(session: .constant(Session(name: "hello")))
}
