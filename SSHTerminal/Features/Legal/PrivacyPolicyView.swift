//
//  PrivacyPolicyView.swift
//  SSHTerminal
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                
                Text("Last Updated: February 2025")
                    .foregroundColor(.secondary)
                
                Group {
                    SectionView(title: "Data We Collect") {
                        Text("SSH Terminal is designed with privacy first. We collect minimal data:")
                        BulletPoint("Server connection profiles (stored locally on your device)")
                        BulletPoint("SSH keys (stored securely in iOS Keychain)")
                        BulletPoint("App preferences and settings (stored locally)")
                        BulletPoint("Crash reports (optional, anonymous)")
                    }
                    
                    SectionView(title: "Data We Don't Collect") {
                        BulletPoint("Your passwords or SSH keys are never transmitted")
                        BulletPoint("Terminal session contents are not logged")
                        BulletPoint("No analytics or tracking without explicit consent")
                        BulletPoint("No third-party advertising networks")
                    }
                    
                    SectionView(title: "How We Use Data") {
                        BulletPoint("Connection profiles: To establish SSH connections")
                        BulletPoint("Settings: To personalize your experience")
                        BulletPoint("Crash reports: To improve app stability (optional)")
                    }
                    
                    SectionView(title: "Third-Party Services") {
                        Text("If you enable AI features:")
                        BulletPoint("Commands may be sent to OpenAI or Anthropic for suggestions")
                        BulletPoint("You control which data is shared")
                        BulletPoint("AI providers have their own privacy policies")
                        
                        Text("\nIf you enable iCloud sync:")
                        BulletPoint("Data is encrypted and stored in your iCloud account")
                        BulletPoint("Subject to Apple's iCloud terms and privacy policy")
                    }
                    
                    SectionView(title: "Your Rights") {
                        BulletPoint("Delete all data: Clear app data in Settings")
                        BulletPoint("Export data: Use backup feature")
                        BulletPoint("Opt-out: Disable analytics and AI features")
                    }
                    
                    SectionView(title: "Security") {
                        BulletPoint("All sensitive data stored in iOS Keychain")
                        BulletPoint("Biometric authentication supported")
                        BulletPoint("No data transmitted to our servers")
                        BulletPoint("All SSH connections are end-to-end encrypted")
                    }
                    
                    SectionView(title: "Children's Privacy") {
                        Text("This app is not directed to children under 13. We do not knowingly collect data from children.")
                    }
                    
                    SectionView(title: "Changes") {
                        Text("We may update this policy. Continued use after changes constitutes acceptance.")
                    }
                    
                    SectionView(title: "Contact") {
                        Text("Questions? Email: privacy@sshterminal.app")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            content
                .font(.body)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}
