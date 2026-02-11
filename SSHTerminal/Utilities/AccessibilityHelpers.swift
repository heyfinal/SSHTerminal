//
//  AccessibilityHelpers.swift
//  SSHTerminal
//
//  Modern accessibility helpers for VoiceOver and Dynamic Type support
//

import SwiftUI
import UIKit

// MARK: - Accessibility View Modifiers

extension View {
    /// Add accessibility label for VoiceOver
    func terminalAccessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }

    /// Add accessibility hint for VoiceOver
    func terminalAccessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }

    /// Add accessibility value for VoiceOver
    func terminalAccessibilityValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }

    /// Combined accessibility configuration
    func terminalAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Make view accessible as a button
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Make view accessible as a header
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    /// Group children for VoiceOver navigation
    func accessibilityGrouped(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }

    /// Announce to VoiceOver when this view appears
    func announceOnAppear(_ message: String) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }
}

// MARK: - VoiceOver Announcements

enum AccessibilityAnnouncement {
    /// Announce a message to VoiceOver
    @MainActor
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Announce screen change
    @MainActor
    static func announceScreenChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    /// Announce layout change
    @MainActor
    static func announceLayoutChange(_ focusElement: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: focusElement)
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Body font that scales with Dynamic Type
    static func dynamicBody(size: CGFloat = 17) -> Font {
        return .system(size: size, design: .default).leading(.loose)
    }

    /// Headline font that scales with Dynamic Type
    static func dynamicHeadline(size: CGFloat = 17) -> Font {
        return .system(size: size, weight: .semibold, design: .default)
    }

    /// Terminal monospaced font with Dynamic Type support
    static func terminalFont(size: CGFloat = 14) -> Font {
        return .system(size: size, design: .monospaced)
    }

    /// Scaled terminal font respecting accessibility settings
    @MainActor
    static func scaledTerminalFont(baseSize: CGFloat = 14) -> Font {
        let scaledSize = UIFontMetrics.default.scaledValue(for: baseSize)
        let clampedSize = min(max(scaledSize, AppConfig.Terminal.minFontSize), AppConfig.Terminal.maxFontSize)
        return .system(size: clampedSize, design: .monospaced)
    }
}

// MARK: - High Contrast Support

extension Color {
    /// Background color that adapts to color scheme
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    /// Foreground color that adapts to color scheme
    static func adaptiveForeground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    /// Terminal green with high contrast support
    static var terminalGreen: Color {
        Color(red: 0.4, green: 0.8, blue: 0.4)
    }

    /// Terminal blue with high contrast support
    static var terminalBlue: Color {
        Color(red: 0.5, green: 0.7, blue: 1.0)
    }

    /// Terminal error red with high contrast support
    static var terminalError: Color {
        Color(red: 1.0, green: 0.4, blue: 0.4)
    }

    /// Terminal background
    static var terminalBackground: Color {
        Color(red: 0.1, green: 0.1, blue: 0.12)
    }

    /// Terminal input area background
    static var terminalInputBackground: Color {
        Color(red: 0.12, green: 0.12, blue: 0.14)
    }
}

// MARK: - Reduce Motion Support

extension View {
    /// Apply animation only when reduce motion is not enabled
    func animationWithMotionPreference<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        self.modifier(ReduceMotionAnimationModifier(animation: animation, value: value))
    }
}

private struct ReduceMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - Accessibility Environment Helpers

struct AccessibilitySettings {
    @MainActor
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    @MainActor
    static var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }

    @MainActor
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    @MainActor
    static var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    @MainActor
    static var shouldDifferentiateWithoutColor: Bool {
        UIAccessibility.shouldDifferentiateWithoutColor
    }

    @MainActor
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
}

// MARK: - Terminal-Specific Accessibility

@MainActor
enum TerminalAccessibility {
    /// Generate accessibility label for terminal output
    static func labelForOutput(_ text: String, type: String) -> String {
        switch type {
        case "command":
            return "Command: \(text)"
        case "output":
            return "Output: \(text)"
        case "error":
            return "Error: \(text)"
        case "system":
            return "System message: \(text)"
        default:
            return text
        }
    }

    /// Announce command execution result
    static func announceCommandResult(success: Bool, output: String? = nil) {
        if success {
            if let output = output, !output.isEmpty {
                let preview = String(output.prefix(100))
                AccessibilityAnnouncement.announce("Command completed. \(preview)")
            } else {
                AccessibilityAnnouncement.announce("Command completed successfully")
            }
        } else {
            AccessibilityAnnouncement.announce("Command failed")
        }
    }

    /// Announce connection status change
    static func announceConnectionStatus(_ status: String, server: String) {
        switch status {
        case "connected":
            AccessibilityAnnouncement.announce("Connected to \(server)")
        case "disconnected":
            AccessibilityAnnouncement.announce("Disconnected from \(server)")
        case "connecting":
            AccessibilityAnnouncement.announce("Connecting to \(server)")
        case "failed":
            AccessibilityAnnouncement.announce("Connection to \(server) failed")
        default:
            break
        }
    }
}
