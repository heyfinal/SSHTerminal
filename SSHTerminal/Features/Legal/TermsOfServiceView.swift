//
//  TermsOfServiceView.swift
//  SSHTerminal
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                
                Text("Last Updated: February 2025")
                    .foregroundColor(.secondary)
                
                Group {
                    SectionView(title: "1. Acceptance of Terms") {
                        Text("By using SSH Terminal, you agree to these terms. If you don't agree, please don't use the app.")
                    }
                    
                    SectionView(title: "2. License") {
                        Text("We grant you a personal, non-exclusive, non-transferable license to use SSH Terminal.")
                        BulletPoint("For personal and commercial use")
                        BulletPoint("Subject to App Store terms")
                        BulletPoint("May be revoked for violations")
                    }
                    
                    SectionView(title: "3. Acceptable Use") {
                        Text("You agree to:")
                        BulletPoint("Use the app legally and ethically")
                        BulletPoint("Only connect to systems you have permission to access")
                        BulletPoint("Not use the app for malicious purposes")
                        BulletPoint("Comply with all applicable laws")
                    }
                    
                    SectionView(title: "4. Prohibited Uses") {
                        Text("You may not:")
                        BulletPoint("Reverse engineer or modify the app")
                        BulletPoint("Use for unauthorized access to systems")
                        BulletPoint("Distribute malware or harmful code")
                        BulletPoint("Violate others' privacy or security")
                    }
                    
                    SectionView(title: "5. Your Responsibility") {
                        BulletPoint("You're responsible for securing your device")
                        BulletPoint("Keep your SSH keys and passwords secure")
                        BulletPoint("Maintain backups of important data")
                        BulletPoint("Use at your own risk")
                    }
                    
                    SectionView(title: "6. Disclaimer") {
                        Text("SSH TERMINAL IS PROVIDED \"AS IS\" WITHOUT WARRANTIES OF ANY KIND.")
                        
                        Text("\nWe don't guarantee:")
                        BulletPoint("Uninterrupted or error-free operation")
                        BulletPoint("Compatibility with all servers")
                        BulletPoint("Data integrity or security")
                        
                        Text("\nUse is at your own risk.")
                    }
                    
                    SectionView(title: "7. Limitation of Liability") {
                        Text("We're not liable for:")
                        BulletPoint("Data loss or corruption")
                        BulletPoint("Security breaches on remote systems")
                        BulletPoint("Damages from app use or inability to use")
                        BulletPoint("Third-party services (AI providers, etc.)")
                    }
                    
                    SectionView(title: "8. Third-Party Services") {
                        Text("AI features use external APIs:")
                        BulletPoint("Subject to their terms and pricing")
                        BulletPoint("You're responsible for API costs")
                        BulletPoint("We don't control their availability")
                    }
                    
                    SectionView(title: "9. Subscription & Payments") {
                        Text("Pro features require subscription:")
                        BulletPoint("Billed through App Store")
                        BulletPoint("Auto-renews unless canceled")
                        BulletPoint("Refunds per App Store policy")
                    }
                    
                    SectionView(title: "10. Termination") {
                        Text("We may suspend or terminate access for:")
                        BulletPoint("Terms violations")
                        BulletPoint("Illegal activity")
                        BulletPoint("Abuse or misuse")
                    }
                    
                    SectionView(title: "11. Changes") {
                        Text("We may update these terms. Continued use after changes means acceptance.")
                    }
                    
                    SectionView(title: "12. Governing Law") {
                        Text("These terms are governed by the laws of [Your Jurisdiction]. Disputes subject to exclusive jurisdiction there.")
                    }
                    
                    SectionView(title: "13. Contact") {
                        Text("Questions? Email: legal@sshterminal.app")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        TermsOfServiceView()
    }
}
