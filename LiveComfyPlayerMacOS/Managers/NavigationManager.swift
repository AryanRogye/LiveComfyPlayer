//
//  NavigationManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/14/25.
//

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

@MainActor
final class NavigationManager: ObservableObject {
    
    static let shared = NavigationManager()
    @Published var activeSessionID: UUID? = nil

    enum Tab: String, CaseIterable, Hashable {
        case home = "Home"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .settings: return "gear"
            }
        }
    }
    
    @Published var selectedTab: Tab? = .home
}
