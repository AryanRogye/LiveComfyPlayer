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
    
    @State private var leftWidth: CGFloat = 150
    @State private var isImporterPresented = false
    @State private var thumbnails: [URL: UIImage] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                addVideoVideo
                    .frame(width: leftWidth)
                
                draggableDivider(geometry: geometry, minLimit: 150, maxLimit: geometry.size.width - 100)
                
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
                        var newWidth = leftWidth + value.translation.width
                        
                        if let minLimit = minLimit {
                            newWidth = max(newWidth, minLimit)
                        } else {
                            newWidth = max(newWidth, 100)
                        }
                        
                        if let maxLimit = maxLimit {
                            newWidth = min(newWidth, maxLimit)
                        } else {
                            newWidth = min(newWidth, geometry.size.width - 100)
                        }
                        
                        leftWidth = newWidth
                    }
            )
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
            session.videoPaths.forEach({ clip in
                loadThumbnail(for: clip.url) {
                    clip.url.stopAccessingSecurityScopedResource()
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
                    
                    ForEach(session.videoPaths, id: \.self) { clip in
                        let video = clip.url
                        ZStack {
                            if let thumbnail = thumbnails[video] {
                                Image(uiImage: thumbnail)
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
                    let fallbackImage = UIImage(systemName: "questionmark.square.dashed") ??
                    UIImage() // fallback empty image
                    continuation.resume(returning: fallbackImage)
                    return
                }
                
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    continuation.resume(returning: uiImage)
                } else {
                    let fallbackImage = UIImage(systemName: "questionmark.square.dashed") ??
                    UIImage()
                    continuation.resume(returning: fallbackImage)
                }
            }
        }
    }
}
