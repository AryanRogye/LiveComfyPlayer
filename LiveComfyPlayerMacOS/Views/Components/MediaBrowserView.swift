//
//  MediaBrowserView.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/15/25.
//

import SwiftUI
import AVFoundation

struct MediaBrowserView: View {
    @Binding var session: Session
    
    @ObservedObject private var sessionManager: SessionManager = .shared
    
    @State private var leftWidth: CGFloat = 300
    @State private var isImporterPresented = false
    @State private var thumbnails: [URL: NSImage] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                addVideoVideo
                    .frame(width: leftWidth)
                
                draggableDivider(geometry: geometry, minLimit: 300, maxLimit: geometry.size.width - 100)
                
                videoPreviewVideo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private func draggableDivider(geometry: GeometryProxy,
                                  minLimit: CGFloat? = nil,
                                  maxLimit: CGFloat? = nil) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 2)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        /// Get the new Width
                        var newWidth = leftWidth + value.translation.width
                        
                        /// Apply Limits if present
                        /// Min limit
                        if let minLimit = minLimit {
                            newWidth = max(newWidth, minLimit)
                        } else {
                            newWidth = max(newWidth, 100)
                        }
                        /// Max Limit
                        if let maxLimit = maxLimit {
                            newWidth = min(newWidth, maxLimit)
                        } else {
                            newWidth = min(newWidth, geometry.size.width - 100)
                        }
                        leftWidth = newWidth
                    }
            )
            .background(Color.clear)
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
    
    // MARK: - Add Video
    
    private var addVideoVideo: some View {
        VStack {
            if session.videoPaths.isEmpty {
                importMediaView()
            } else {
                importedMediaView
            }
        }
        .onAppear {
            // We Wanna load thumbnails for the
            session.videoPaths.forEach({ video in
                loadThumbnail(for: video) {
                    video.stopAccessingSecurityScopedResource()
                }
            })
        }
    }
    
    private var importedMediaView: some View {
        GeometryReader { geometry in
            let itemSize: CGFloat = 100
            let spacing: CGFloat = 10
            let columnsCount = max(Int((geometry.size.width + spacing) / (itemSize + spacing)), 1)
            
            let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: columnsCount)
            
            
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
                    // Ensure the import button is there so u can always add something
                    importMediaView(width: 60, height: 60, paddingTop: 10)
                    
                    ForEach(session.videoPaths, id: \.self) { video in
                        ZStack {
                            if let thumbnail = thumbnails[video] {
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: itemSize, height: itemSize)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: itemSize, height: itemSize)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    )
                            }
                        }
                        .onDrag {
                            let provider = NSItemProvider(object: video as NSURL)
                            return provider
                        }
                    }
                }
                .padding(.horizontal, spacing)
            }
        }
    }
    
    private func importMediaView(width: CGFloat = 15, height: CGFloat = 15, paddingTop: CGFloat = 0) -> some View {
        Button(action: {
            isImporterPresented = true
        }) {
            VStack {
                VStack {
                    Image(systemName: "arrow.down")
                        .resizable()
                        .frame(width: width, height: height)
                        .foregroundStyle(.primary)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray)
                }
                Text("Import Media")
                    .font(.caption)
                
            }
        }
        .buttonStyle(.plain)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.movie, .video],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    if url.startAccessingSecurityScopedResource() {
                        sessionManager.addVideoPath(url, to: session)
                        loadThumbnail(for: url) {
                            url.stopAccessingSecurityScopedResource() // Stop access after thumbnail loads
                        }
                    }
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .padding(.top, paddingTop)
    }
    
    // MARK: - Video Preview
    private var videoPreviewVideo: some View {
        VStack {
            Text("")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue.opacity(0.2))
        }
    }
    
    // MARK: - Private API's
    
    private func loadThumbnail(for url: URL, completion: @escaping () -> Void) {
        Task {
            let thumbnail = await generateThumbnail(for: url)
            await MainActor.run {
                thumbnails[url] = thumbnail
                completion()  // Call completion after thumbnail is set
            }
        }
    }
    
    private func generateThumbnail(for url: URL) async -> NSImage {
        return await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 300, height: 300)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                if let error = error {
                    print("❌ Thumbnail generation failed for \(url.lastPathComponent): \(error.localizedDescription)")
                    let fallbackImage = NSImage(systemSymbolName: "questionmark.square.dashed", accessibilityDescription: "Missing Thumbnail")
                    ?? NSImage(size: NSSize(width: 64, height: 64))
                    continuation.resume(returning: fallbackImage)
                    return
                }
                
                if let cgImage = cgImage {
                    let nsImage = NSImage(cgImage: cgImage, size: .zero)
                    continuation.resume(returning: nsImage)
                } else {
                    let fallbackImage = NSImage(systemSymbolName: "questionmark.square.dashed", accessibilityDescription: "Missing Thumbnail")
                    ?? NSImage(size: NSSize(width: 64, height: 64))
                    continuation.resume(returning: fallbackImage)
                }
            }
        }
    }
}
