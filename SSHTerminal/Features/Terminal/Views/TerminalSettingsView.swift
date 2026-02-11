//
//  TerminalSettingsView.swift
//  SSHTerminal
//
//  Terminal appearance and behavior settings
//

import SwiftUI

enum TerminalTheme: String, CaseIterable {
    case defaultDark = "Green on Black"
    case blue = "Blue Terminal"
    case amber = "Amber Terminal"
    case dracula = "Dracula"
    
    var description: String { rawValue }
}

struct TerminalSettings {
    var theme: TerminalTheme = .defaultDark
    var fontSize: CGFloat = 14
    var enableBell: Bool = true
    var cursorBlink: Bool = true
}

struct TerminalSettingsView: View {
    @Binding var settings: TerminalSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $settings.theme) {
                        ForEach(TerminalTheme.allCases, id: \.self) { theme in
                            Text(theme.description).tag(theme)
                        }
                    }
                    
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(settings.fontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settings.fontSize, in: 10...24, step: 1)
                }
                
                Section("Behavior") {
                    Toggle("Enable Bell", isOn: $settings.enableBell)
                    Toggle("Cursor Blink", isOn: $settings.cursorBlink)
                }
            }
            .navigationTitle("Terminal Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
