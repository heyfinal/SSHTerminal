//
//  HapticManager.swift
//  SSHTerminal
//

import UIKit
import SwiftUI

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Convenience methods
    func success() {
        notification(.success)
    }
    
    func error() {
        notification(.error)
    }
    
    func warning() {
        notification(.warning)
    }
    
    func light() {
        impact(.light)
    }
    
    func medium() {
        impact(.medium)
    }
    
    func heavy() {
        impact(.heavy)
    }
}

// SwiftUI View extension
extension View {
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.onTapGesture {
            switch type {
            case .success:
                HapticManager.shared.success()
            case .error:
                HapticManager.shared.error()
            case .warning:
                HapticManager.shared.warning()
            case .light:
                HapticManager.shared.light()
            case .medium:
                HapticManager.shared.medium()
            case .heavy:
                HapticManager.shared.heavy()
            case .selection:
                HapticManager.shared.selection()
            }
        }
    }
}

enum HapticFeedbackType {
    case success, error, warning
    case light, medium, heavy
    case selection
}
