//
//  TerminalKeyboardToolbar.swift
//  SSHTerminal
//
//  Custom keyboard toolbar for terminal shortcuts
//

import SwiftUI

struct TerminalKeyboardToolbar: View {
    let onKey: (String) -> Void
    @StateObject private var commandAI = CommandAIService.shared
    @State private var showAIInput = false
    @State private var aiInput = ""
    @State private var isConverting = false
    
    private let keys = [
        ("Tab", "\t"),
        ("Esc", "\u{1B}"),
        ("↑", "\u{1B}[A"),
        ("↓", "\u{1B}[B"),
        ("←", "\u{1B}[D"),
        ("→", "\u{1B}[C"),
        ("Ctrl+C", "\u{03}"),
        ("Ctrl+D", "\u{04}"),
        ("Ctrl+Z", "\u{1A}")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // AI command input
            if showAIInput {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.blue)
                    
                    TextField("network config, disk space, etc...", text: $aiInput)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .disabled(isConverting)
                        .onSubmit {
                            Task { await convertToCommand() }
                        }
                    
                    if isConverting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Button {
                        showAIInput = false
                        aiInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
            }
            
            // Keyboard shortcuts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // AI button
                    if commandAI.isEnabled {
                        Button {
                            showAIInput.toggle()
                        } label: {
                            Image(systemName: showAIInput ? "wand.and.stars.inverse" : "wand.and.stars")
                                .font(.system(size: 14))
                                .foregroundColor(showAIInput ? .blue : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(showAIInput ? Color.blue.opacity(0.2) : Color.gray.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                    
                    ForEach(keys, id: \.0) { key in
                        Button {
                            onKey(key.1)
                        } label: {
                            Text(key.0)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(height: 44)
        }
        .background(Color.black.opacity(0.95))
    }
    
    private func convertToCommand() async {
        guard !aiInput.isEmpty else { return }
        isConverting = true
        
        // Try quick templates first
        if let quick = commandAI.quickCommand(for: aiInput) {
            onKey(quick + "\n")
            aiInput = ""
            showAIInput = false
            isConverting = false
            return
        }
        
        // Use AI for conversion
        if let command = await commandAI.textToCommand(aiInput) {
            onKey(command + "\n")
            aiInput = ""
            showAIInput = false
        }
        
        isConverting = false
    }
}
