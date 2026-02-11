//
//  BackupSettingsView.swift
//  SSHTerminal
//

import SwiftUI

struct BackupSettingsView: View {
    @AppStorage("iCloudSync") private var iCloudSync = false
    @AppStorage("backupServers") private var backupServers = true
    @AppStorage("backupKeys") private var backupKeys = false
    @AppStorage("backupSnippets") private var backupSnippets = true
    
    var body: some View {
        List {
            Section {
                Toggle("Enable iCloud Sync", isOn: $iCloudSync)
            } footer: {
                Text("Sync your settings and data across all your devices")
            }
            
            if iCloudSync {
                Section("What to Sync") {
                    Toggle("Server Profiles", isOn: $backupServers)
                    Toggle("SSH Keys", isOn: $backupKeys)
                    Toggle("Snippets Library", isOn: $backupSnippets)
                }
                
                Section {
                    Button("Sync Now") {
                        // Trigger manual sync
                    }
                    
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text("Just now")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Local Backup") {
                Button("Export All Data") {
                    // Export data
                }
                
                Button("Import Data") {
                    // Import data
                }
            }
        }
        .navigationTitle("Backup & Sync")
    }
}

#Preview {
    NavigationView {
        BackupSettingsView()
    }
}
