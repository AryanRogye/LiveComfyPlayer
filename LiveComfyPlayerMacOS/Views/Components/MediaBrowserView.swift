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
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                addVideoVideo
                    .frame(width: leftWidth)
                
                draggableDivider(geometry: geometry)
                
                videoPreviewVideo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func draggableDivider(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 2)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let newWidth = leftWidth + value.translation.width
                        if newWidth > 100 && newWidth < geometry.size.width - 100 {
                            leftWidth = newWidth
                        }
                    }
            )
            .background(Color.clear)
#if os(macOS)
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
#elseif os(iOS)
            .hoverEffect(.highlight) // Optional for iPadOS mouse hover
#endif
    }
    
    // MARK: - Add Video
    @State private var isImporterPresented = false
    #if os(macOS)
    @State private var thumbnails: [URL: NSImage] = [:]
    #elseif os(iOS)
    @State private var thumbnails: [URL: UIImage] = [:]
    #endif
    
    private var addVideoVideo: some View {
        VStack {
            if session.videoPaths.isEmpty {
                importMediaView
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
        VStack {
            let columns = [
                GridItem(.flexible(minimum: 100)),
                GridItem(.flexible(minimum: 100))
            ]
            LazyVGrid(columns: columns) {
                ForEach(session.videoPaths, id: \.self) { video in
                    if let thumbnail = thumbnails[video] {
                        #if os(iOS)
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                        #elseif os(macOS)
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                        #endif
                    } else {
                        // Show placeholder while loading
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                }
            }
        }
    }
    
    private var importMediaView: some View {
        Button(action: {
            isImporterPresented = true
        }) {
            VStack {
                VStack {
                    Image(systemName: "arrow.down")
                        .resizable()
                        .frame(width: 15, height: 15)
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
    }
    
    // MARK: - Video Preview
    private var videoPreviewVideo: some View {
        VStack {
            Text("hello")
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
    
    #if os(macOS)
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
    #elseif os(iOS)
    private func generateThumbnail(for url: URL) async -> UIImage {
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
                    let fallbackImage = UIImage(systemName: "questionmark.square.dashed")
                    ?? UIImage()
                    continuation.resume(returning: fallbackImage)
                    return
                }
                
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    continuation.resume(returning: uiImage)
                } else {
                    let fallbackImage = UIImage(systemName: "questionmark.square.dashed")
                    ?? UIImage()
                    continuation.resume(returning: fallbackImage)
                }
            }
        }
    }
    #endif
}
