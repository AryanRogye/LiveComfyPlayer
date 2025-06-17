//
//  LiveComfyPlayerMacOSApp.swift
//  LiveComfyPlayerMacOS
//
//  Created by Aryan Rogye on 6/13/25.
//

import SwiftUI

@main
struct LiveComfyPlayerMacOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                MultiPeerManager.shared.stop()
            }
        }
    }
}
