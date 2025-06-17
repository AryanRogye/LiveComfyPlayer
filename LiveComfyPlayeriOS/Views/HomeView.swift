//
//  HomeView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/13/25.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Environment variables
    @Environment(\.colorScheme) private var colorScheme
    
    
    // MARK: -  Observed Objects
    @ObservedObject private var sessionManager: SessionManager = .shared
    @ObservedObject private var navigationManager: NavigationManager = .shared
    
    // MARK: -  State variables
    ///     Add Relevat -
    @State private var roomName: String = ""
    @State private var showAddButton: Bool = false
    ///     List Relevat -
    @State private var hoveredID: UUID?
    
    
    var body: some View {
        VStack {
            if showAddButton {
                addVideos
            } else {
                videoList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Home")
        .background(.ultraThinMaterial)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddButton.toggle() }) {
                    /// Add Button
                    Image(systemName: !showAddButton ? "plus" : "minus")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - ADD Section
    private var addVideos: some View {
        VStack {
            addVideoTitle
            
            Divider()
                .padding([.horizontal, .bottom])
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Room Name:")
                        .frame(width: 100, alignment: .trailing)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter room name", text: $roomName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        showAddButton.toggle()
                        roomName = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Start Room") {
                        /// Create a Session
                        let session = Session(name: roomName)
                        /// Add it
                        sessionManager.addSession(session)
                        showAddButton.toggle()
                        roomName = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(roomName.isEmpty)
                }
                .padding(20)
                
            }
            
            Spacer()
        }
    }
    
    private var addVideoTitle: some View {
        HStack {
            Text("Add Videos")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
    }
    
    
    // MARK: - Video List Section
    private var videoList: some View {
        VStack {
            videoListTitle
            Divider()
                .padding([.horizontal, .bottom])
            
            roomsListView
            Spacer()
        }
    }
    
    private var roomsListView: some View {
        ScrollView {
            ForEach(sessionManager.sessions.indices, id: \.self) { index in
                let session = sessionManager.sessions[index]
                Button(action: {
                    navigationManager.activeSessionID = session.id
                }) {
                    sessionRow(session)
                        .padding(2)
                        .onHover { hovering in
                            hoveredID = hovering ? session.id : nil
                        }
                        .background {
                            if hoveredID == session.id {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor.opacity(0.1))
                            } else if colorScheme == .dark {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground).opacity(0.5))
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.separator), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // session row
    private func sessionRow(_ session: Session) -> some View {
        HStack(spacing: 12) {
            // Room icon
            Image(systemName: "video.fill")
                .foregroundColor(.accentColor)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(session.videoPaths.count) videos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                // TODO: add a edit
                Button("Edit Room") {
                    // Edit action
                }
                Divider()
                Button("Delete", role: .destructive) {
                    sessionManager.removeSession(session)
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .frame(width: 28, height: 28) // ensures size doesn't collapse
            .contentShape(Rectangle())
        }
        .padding(12)
    }
    
    private var videoListTitle: some View {
        HStack {
            Text("Video List")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
