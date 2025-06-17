//
//  MediaTimelineView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/15/25.
//

import SwiftUI

struct MediaTimelineView: View {
    
    @State private var isHovering: Bool = false
    @ObservedObject private var sessionManager: SessionManager = .shared
    @Binding var session: Session
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                startSessionPreview
                    .padding(.top, 3)
                
                timelineView
                    .frame(width: geo.size.width)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
    
    var startSessionPreview: some View {
        HStack {
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                    .padding()
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    var timelineView: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                /// Actual View of the timeline
                if session.timelinePaths.isEmpty {
                    Text("Drop media files here to create a timeline")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    sessionTimelineDroppedViews
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 90)
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)
        .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                        DispatchQueue.main.async {
                            handleTimelineDrop(of: url)
                        }
                    }
                }
            }
            return true
        }
        .padding(.horizontal, 10)
    }
    
    var sessionTimelineDroppedViews: some View {
        ForEach(session.timelinePaths) { clip in
            timelineBox(for: clip)
        }
    }
    
    private func timelineBox(for clip: Clip) -> some View {
        VStack(spacing: 4) {
            // Fake visual "clip"
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor)
                .frame(width: 140, height: 40)
                .overlay(
                    Text(clip.url.deletingPathExtension().lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 6),
                    alignment: .leading
                )
                .shadow(radius: 2, y: 1)
            
            // Fake duration label
            Text("00:12") // placeholder
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 140)
    }
    
    private func handleTimelineDrop(of url: URL) {
        sessionManager.addVideoToTimeline(url, for: session)
    }
}
