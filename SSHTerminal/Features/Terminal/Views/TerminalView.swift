//
//  TerminalView.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import SwiftUI
import AudioToolbox

struct TerminalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TerminalViewModel
    @StateObject private var aiService = AIService.shared
    @State private var showingSettings = false
    @State private var showingAIChat = false
    @State private var showingAISettings = false
    @State private var showErrorExplanation = false
    @State private var lastError: String?
    @State private var lastCommand: String?
    @State private var terminalSettings = TerminalSettings()
    
    init(session: SSHSession) {
        _viewModel = StateObject(wrappedValue: TerminalViewModel(session: session))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Enhanced Terminal Display
                    EnhancedTerminalView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // AI Command Suggestions (if enabled)
                    if aiService.isEnabled {
                        CommandSuggestionView(
                            context: currentContext,
                            onSelectCommand: { command in
                                Task {
                                    await viewModel.sendInput(command + "\n")
                                }
                            }
                        )
                    }
                    
                    Divider()
                        .background(Color.green.opacity(0.3))
                    
                    // Custom keyboard toolbar
                    TerminalKeyboardToolbar { keyCode in
                        Task {
                            await viewModel.sendInput(keyCode)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.session.server.name)
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    connectionStatusView
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if aiService.isEnabled {
                            Button {
                                showingAIChat = true
                            } label: {
                                Label("AI Assistant", systemImage: "brain.head.profile")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Menu {
                            Button {
                                showingSettings = true
                            } label: {
                                Label("Terminal Settings", systemImage: "gearshape")
                            }
                            
                            Button {
                                showingAISettings = true
                            } label: {
                                Label("AI Settings", systemImage: "brain")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.disconnect()
                                    dismiss()
                                }
                            } label: {
                                Label("Disconnect", systemImage: "xmark.circle.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                TerminalSettingsView(settings: $terminalSettings)
            }
            .sheet(isPresented: $showingAIChat) {
                AIAssistantView(context: currentContext, onInsertCommand: { command in
                    Task {
                        await viewModel.sendInput(command + "\n")
                    }
                    showingAIChat = false
                })
            }
            .sheet(isPresented: $showingAISettings) {
                AISettingsView()
            }
            .sheet(isPresented: $showErrorExplanation) {
                if let error = lastError, let command = lastCommand {
                    ErrorExplanationView(
                        error: error,
                        command: command,
                        context: currentContext,
                        onSelectFix: { fix in
                            Task {
                                await viewModel.sendInput(fix + "\n")
                            }
                            showErrorExplanation = false
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .onChange(of: viewModel.session.output) { _, newOutput in
                detectErrors(in: newOutput)
            }
        }
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var statusColor: Color {
        switch viewModel.session.state {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected, .failed:
            return .red
        }
    }
    
    private var statusText: String {
        switch viewModel.session.state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .failed:
            return "Failed"
        }
    }
    
    private var currentContext: CommandContext {
        CommandContext(
            currentDirectory: extractCurrentDirectory(),
            osInfo: "Linux", // Could be detected from session
            serverName: viewModel.session.server.name,
            lastCommand: lastCommand,
            lastOutput: viewModel.session.output
        )
    }
    
    private func extractCurrentDirectory() -> String {
        // Try to extract from PS1 or last pwd command
        // For now, return default
        return "~"
    }
    
    private func detectErrors(in output: String) {
        guard aiService.isEnabled else { return }
        
        let errorPatterns = [
            "command not found",
            "permission denied",
            "no such file or directory",
            "connection refused",
            "cannot access",
            "error:",
            "failed"
        ]
        
        let lowercased = output.lowercased()
        for pattern in errorPatterns {
            if lowercased.contains(pattern) {
                // Extract the error line
                let lines = output.split(separator: "\n")
                if let errorLine = lines.last(where: { $0.lowercased().contains(pattern) }) {
                    lastError = String(errorLine)
                    // Extract command from output (look for $ prompt)
                    if let cmdLine = lines.last(where: { $0.starts(with: "$") }) {
                        lastCommand = String(cmdLine.dropFirst().trimmingCharacters(in: .whitespaces))
                    }
                    showErrorExplanation = true
                    break
                }
            }
        }
    }
}

