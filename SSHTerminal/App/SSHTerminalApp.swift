//
//  SSHTerminalApp.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import SwiftUI

@main
struct SSHTerminalApp: App {
    @StateObject private var onboardingManager = OnboardingManager()
    
    var body: some Scene {
        WindowGroup {
            if onboardingManager.hasCompletedOnboarding {
                ServerListView()
            } else {
                WelcomeView()
            }
        }
    }
}
