//
//  SettingsView.swift
//  SSHTerminal
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: .purple,
                            title: "Appearance",
                            subtitle: "Theme, colors, font"
                        )
                    }
                    
                    NavigationLink(destination: TerminalSettingsView(settings: .constant(TerminalSettings()))) {
                        SettingsRow(
                            icon: "terminal.fill",
                            iconColor: .blue,
                            title: "Terminal",
                            subtitle: "Behavior, keyboard"
                        )
                    }
                    
                    NavigationLink(destination: SecuritySettingsView()) {
                        SettingsRow(
                            icon: "lock.shield.fill",
                            iconColor: .red,
                            title: "Security & Privacy",
                            subtitle: "Biometrics, timeout"
                        )
                    }
                }
                
                Section {
                    NavigationLink(destination: AISettingsView()) {
                        SettingsRow(
                            icon: "brain.head.profile",
                            iconColor: .pink,
                            title: "AI Assistant",
                            subtitle: "API keys, models"
                        )
                    }
                    
                    NavigationLink(destination: BackupSettingsView()) {
                        SettingsRow(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "Backup & Sync",
                            subtitle: "iCloud integration"
                        )
                    }
                }
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .orange,
                            title: "About",
                            subtitle: "Version, credits"
                        )
                    }
                    
                    Link(destination: URL(string: "https://sshterminal.app/privacy")!) {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            iconColor: .green,
                            title: "Privacy Policy",
                            subtitle: "Data handling"
                        )
                    }
                    
                    Link(destination: URL(string: "https://sshterminal.app/support")!) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .indigo,
                            title: "Support & FAQ",
                            subtitle: "Get help"
                        )
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.gradient)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
