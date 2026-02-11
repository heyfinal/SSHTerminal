//
//  TerminalView.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import SwiftUI
import AudioToolbox
import Citadel

struct TerminalView: View {
    @Environment(\.dismiss) private var dismiss
    let session: SSHSession
    @State private var sshClient: SSHClient?
    @State private var isConnected = false
    @State private var showingSettings = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let client = sshClient, isConnected {
                        // Native SwiftTerm with PTY
                        PTYTerminalView(client: client, isConnected: $isConnected)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Loading state
                        VStack(spacing: 20) {
                            ProgressView()
                            Text("Connecting to \(session.server.host)...")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                    
            }
            .navigationTitle(session.server.name)
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    connectionStatusView
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            isConnected = false
                            dismiss()
                        } label: {
                            Label("Disconnect", systemImage: "xmark.circle.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                TerminalSettingsView(settings: .constant(TerminalSettings()))
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK") { dismiss() }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .task {
                await connectToSSH()
            }
            .onChange(of: isConnected) { _, connected in
                if !connected {
                    dismiss()
                }
            }
        }
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? .green : .yellow)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : "Connecting")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func connectToSSH() async {
        do {
            // Get the SSH client from SSHService
            guard let client = await SSHService.shared.getClient(for: session) else {
                throw SSHError.connectionFailed("No SSH client available")
            }
            
            print("✅ Got SSH client, setting up PTY...")
            await MainActor.run {
                self.sshClient = client
                self.isConnected = true
            }
        } catch {
            print("❌ Failed to get SSH client: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showingError = true
            }
        }
    }
}

