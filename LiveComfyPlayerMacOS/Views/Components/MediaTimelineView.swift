//
//  MediaTimelineView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/15/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MediaTimelineView: View {
    
    @EnvironmentObject private var sessionManager: SessionManager
    @Binding var session: Session
    @Binding var topHeight: CGFloat
    
    @State private var isHovering: Bool = false
    @State private var hoverX: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    startSessionPreview
                        .padding(.top, 3)
                    
                    timelineView
                        .frame(width: geo.size.width)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            HoverTrackingView { x in
                hoverX = x
            }
            
            showHoverIndicator(geometry: geo)
        }
    }
    
    func showHoverIndicator(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.accentColor.opacity(isHovering ? 0.5 : 0))
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .position(x: hoverX, y: geometry.size.height - topHeight)
            .animation(.easeInOut, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
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
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
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
        .contextMenu {
            Button(action: {
                sessionManager.removeTimelineClip(clip, from: session)
            }) {
                Label("Remove Clip", systemImage: "trash")
            }
        }
    }
    
    private func handleTimelineDrop(of url: URL) {
        sessionManager.addVideoToTimeline(url, for: session)
    }
}


struct HoverTrackingView: NSViewRepresentable {
    var onUpdate: (CGFloat) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = TrackingNSView()
        view.onUpdate = onUpdate
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class TrackingNSView: NSView {
        var onUpdate: ((CGFloat) -> Void)?
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            
            let area = NSTrackingArea(
                rect: bounds,
                options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(area)
        }
        
        override func mouseMoved(with event: NSEvent) {
            let location = convert(event.locationInWindow, from: nil)
            onUpdate?(location.x)
        }
    }
}
