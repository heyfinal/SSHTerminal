//
//  SecuritySettingsView.swift
//  SSHTerminal
//

import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    @AppStorage("useBiometrics") private var useBiometrics = true
    @AppStorage("autoLockTimeout") private var autoLockTimeout: Double = 5
    @AppStorage("requireAuthOnLaunch") private var requireAuthOnLaunch = true
    @AppStorage("hideScreenshots") private var hideScreenshots = false
    
    @State private var biometricType: LABiometryType = .none
    
    var body: some View {
        List {
            Section {
                Toggle(biometricLabel, isOn: $useBiometrics)
                Toggle("Require on Launch", isOn: $requireAuthOnLaunch)
                    .disabled(!useBiometrics)
            } header: {
                Text("Biometric Authentication")
            } footer: {
                Text("Use \(biometricLabel.lowercased()) to unlock the app and access sensitive data")
            }
            
            Section("Auto-Lock") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Lock After")
                        Spacer()
                        Text(timeoutLabel)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $autoLockTimeout, in: 1...30, step: 1)
                }
            }
            
            Section {
                Toggle("Hide from App Switcher", isOn: $hideScreenshots)
            } header: {
                Text("Screen Security")
            } footer: {
                Text("Prevent sensitive information from appearing in screenshots and app switcher")
            }
            
            Section("Data Management") {
                Button(role: .destructive) {
                    // Clear saved credentials
                } label: {
                    Label("Clear All Saved Passwords", systemImage: "trash")
                }
                
                Button(role: .destructive) {
                    // Clear SSH keys
                } label: {
                    Label("Clear All SSH Keys", systemImage: "key.slash")
                }
            }
        }
        .navigationTitle("Security & Privacy")
        .onAppear {
            checkBiometricType()
        }
    }
    
    private var biometricLabel: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    private var timeoutLabel: String {
        if autoLockTimeout < 2 {
            return "1 minute"
        } else if autoLockTimeout == 30 {
            return "Never"
        } else {
            return "\(Int(autoLockTimeout)) minutes"
        }
    }
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }
}

#Preview {
    NavigationView {
        SecuritySettingsView()
    }
}
