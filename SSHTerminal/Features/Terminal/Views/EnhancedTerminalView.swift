//
//  EnhancedTerminalView.swift
//  SSHTerminal
//
//  Enhanced terminal view with proper prompt and formatting
//

import SwiftUI

struct EnhancedTerminalView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var input = ""
    @State private var commandHistory: [String] = []
    @State private var historyIndex = -1
    @FocusState private var isInputFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Terminal output area (read-only history)
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.terminalLines) { line in
                            lineView(for: line)
                                .accessibilityLabel(TerminalAccessibility.labelForOutput(line.text, type: line.type.accessibilityType))
                        }

                        // Anchor point for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onChange(of: viewModel.terminalLines.count) { _ in
                        if !reduceMotion {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        } else {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color.terminalBackground)
            .accessibilityLabel("Terminal output")
            .accessibilityHint("Scrollable terminal history. Use VoiceOver gestures to navigate lines.")

            // Current input line (always visible, always active)
            if viewModel.session.state == .connected {
                HStack(spacing: 0) {
                    promptText
                        .accessibilityHidden(true) // Prompt is decorative, TextField has full context
                    TextField("Enter command", text: $input)
                        .foregroundColor(.white)
                        .font(.system(.body, design: .monospaced))
                        .focused($isInputFocused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.send)
                        .onSubmit {
                            sendCommand()
                        }
                        .accessibilityLabel("Command input")
                        .accessibilityHint("Enter a command and press return to execute. Use up and down arrows to navigate command history.")
                        .accessibilityValue(input.isEmpty ? "Empty" : input)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.terminalInputBackground)
            }
        }
        .onAppear {
            // Initialize terminal
            Task {
                await viewModel.initializeTerminal()
            }
            // Delay focus to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
            // Announce for VoiceOver users
            TerminalAccessibility.announceConnectionStatus("connected", server: viewModel.hostname)
        }
        .onKeyPress(.upArrow) {
            navigateHistory(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateHistory(direction: .down)
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SSH Terminal for \(viewModel.hostname)")
    }
    
    private var promptText: some View {
        HStack(spacing: 0) {
            Text(viewModel.username)
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.4))
            Text("@")
                .foregroundColor(.white)
            Text(viewModel.hostname)
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.4))
            Text(":")
                .foregroundColor(.white)
            Text(viewModel.currentDirectory)
                .foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0))
            Text(viewModel.isRoot ? "# " : "$ ")
                .foregroundColor(.white)
        }
        .font(.system(.body, design: .monospaced))
    }
    
    @ViewBuilder
    private func lineView(for line: TerminalLine) -> some View {
        switch line.type {
        case .prompt:
            Text(line.text)
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.4))
                .font(.system(.body, design: .monospaced))
        case .command:
            Text(line.text)
                .foregroundColor(.white)
                .font(.system(.body, design: .monospaced))
        case .output:
            Text(line.text)
                .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                .font(.system(.body, design: .monospaced))
        case .error:
            Text(line.text)
                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                .font(.system(.body, design: .monospaced))
        case .system:
            Text(line.text)
                .foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0))
                .font(.system(.body, design: .monospaced))
        }
    }
    
    private func sendCommand() {
        guard !input.isEmpty else { return }
        
        let command = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear input IMMEDIATELY (before command executes)
        input = ""
        
        // Handle built-in commands
        if command == "clear" {
            Task {
                await viewModel.clearScreen()
                // Focus stays on TextField automatically
            }
            return
        }
        
        // Add to history
        if !command.isEmpty {
            commandHistory.append(command)
            historyIndex = commandHistory.count
        }
        
        // Send command
        Task {
            await viewModel.executeEnhancedCommand(command)
            // TextField maintains focus automatically since it's visible
        }
    }
    
    private func navigateHistory(direction: HistoryDirection) {
        guard !commandHistory.isEmpty else { return }
        
        switch direction {
        case .up:
            if historyIndex > 0 {
                historyIndex -= 1
                input = commandHistory[historyIndex]
            }
        case .down:
            if historyIndex < commandHistory.count - 1 {
                historyIndex += 1
                input = commandHistory[historyIndex]
            } else {
                historyIndex = commandHistory.count
                input = ""
            }
        }
    }
    
    enum HistoryDirection {
        case up, down
    }
}
