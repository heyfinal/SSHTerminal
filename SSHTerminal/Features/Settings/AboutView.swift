//
//  AboutView.swift
//  SSHTerminal
//

import SwiftUI

struct AboutView: View {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00f2fe"), Color(hex: "4facfe")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("SSH Terminal")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        Text("Version \(version) (\(build))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section("Links") {
                Link(destination: URL(string: "https://sshterminal.app")!) {
                    Label("Website", systemImage: "globe")
                }
                
                Link(destination: URL(string: "https://sshterminal.app/support")!) {
                    Label("Support", systemImage: "questionmark.circle")
                }
                
                Link(destination: URL(string: "https://github.com/sshterminal/ios")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                Link(destination: URL(string: "https://twitter.com/sshterminal")!) {
                    Label("Twitter", systemImage: "at")
                }
            }
            
            Section("Legal") {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                
                NavigationLink("Terms of Service") {
                    TermsOfServiceView()
                }
                
                NavigationLink("Open Source Licenses") {
                    LicensesView()
                }
            }
            
            Section("Credits") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built with:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• SwiftTerm - Terminal emulator")
                    Text("• Citadel - SSH library")
                    Text("• OpenSSL - Cryptography")
                }
                .font(.caption)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
