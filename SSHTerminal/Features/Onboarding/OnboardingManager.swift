//
//  OnboardingManager.swift
//  SSHTerminal
//

import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var currentPage = 0
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
