//
//  AnimationConstants.swift
//  SSHTerminal
//

import SwiftUI

struct AnimationConstants {
    // Standard animations
    static let fast = Animation.easeOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    
    // Spring animations
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    
    // Durations
    static let quickDuration: Double = 0.2
    static let standardDuration: Double = 0.3
    static let slowDuration: Double = 0.5
}

// Custom transitions
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale.combined(with: .opacity)
    }
}

// View modifiers for common animations
struct ShakeAnimation: ViewModifier {
    let shakes: Int
    @Binding var trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: trigger ? CGFloat(shakes * 10) : 0)
            .animation(
                trigger ? 
                Animation.spring(response: 0.2, dampingFraction: 0.2).repeatCount(shakes, autoreverses: true) :
                .default,
                value: trigger
            )
    }
}

extension View {
    func shake(shakes: Int = 2, trigger: Binding<Bool>) -> some View {
        modifier(ShakeAnimation(shakes: shakes, trigger: trigger))
    }
}
