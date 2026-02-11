//
//  OnboardingManager.swift
//  SSHTerminal
//

import SwiftUI

class OnboardingManager: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var currentPage = 0
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
