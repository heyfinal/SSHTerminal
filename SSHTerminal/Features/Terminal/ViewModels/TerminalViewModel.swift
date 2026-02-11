//
//  TerminalViewModel.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation
import Combine

struct TerminalLine: Identifiable {
    let id = UUID()
    let type: LineType
    let text: String
    let timestamp: Date

    init(type: LineType, text: String, timestamp: Date = Date()) {
        self.type = type
        self.text = text
        self.timestamp = timestamp
    }

    enum LineType {
        case prompt
        case command
        case output
        case error
        case system

        /// Accessibility type string for VoiceOver
        var accessibilityType: String {
            switch self {
            case .prompt: return "prompt"
            case .command: return "command"
            case .output: return "output"
            case .error: return "error"
            case .system: return "system"
            }
        }

        /// Accessibility description for VoiceOver
        var accessibilityDescription: String {
            switch self {
            case .prompt: return "Prompt"
            case .command: return "Command"
            case .output: return "Output"
            case .error: return "Error"
            case .system: return "System message"
            }
        }
    }
}

@MainActor
class TerminalViewModel: ObservableObject {
    @Published var session: SSHSession
    @Published var currentCommand = ""
    @Published var isExecuting = false
    @Published var pendingOutput = ""
    @Published var terminalSize: (cols: Int, rows: Int) = (80, 24)

    // Enhanced terminal properties
    @Published var terminalLines: [TerminalLine] = []
    @Published var username: String = "user"
    @Published var hostname: String = "localhost"
    @Published var currentDirectory: String = "~"
    @Published var isRoot: Bool = false

    // Buffer management
    @Published var isBufferTruncated: Bool = false
    @Published var totalLinesDropped: Int = 0

    private let sshService = SSHService.shared
    private var cancellables = Set<AnyCancellable>()
    private var isInitialized = false

    // Configuration for output management
    private let maxTerminalLines = AppConfig.Terminal.maxHistoryLines
    private let maxOutputBufferSize = AppConfig.Terminal.maxOutputBufferSize
    private let lineBatchSize = 100 // Process lines in batches for performance
    
    init(session: SSHSession) {
        self.session = session
        self.hostname = session.server.host
        self.username = session.server.username
        
        session.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Monitor session output changes and feed to terminal
        session.$output
            .sink { [weak self] newOutput in
                self?.pendingOutput = newOutput
            }
            .store(in: &cancellables)
    }
    
    func initializeTerminal() async {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Add welcome message
        addSystemLine("Connected to \(hostname)")
        addSystemLine("Last login: \(Date().formatted(date: .abbreviated, time: .shortened))")
        addSystemLine("")
        
        // Get initial environment info
        await updateEnvironment()
    }
    
    func updateEnvironment() async {
        // Get username
        if let whoami = try? await sshService.executeCommand("whoami", in: session) {
            username = whoami.trimmingCharacters(in: .whitespacesAndNewlines)
            isRoot = username == "root"
        }
        
        // Get hostname
        if let host = try? await sshService.executeCommand("hostname", in: session) {
            hostname = host.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Get current directory
        if let pwd = try? await sshService.executeCommand("pwd", in: session) {
            let dir = pwd.trimmingCharacters(in: .whitespacesAndNewlines)
            currentDirectory = formatDirectory(dir)
        }
    }
    
    func executeEnhancedCommand(_ command: String) async {
        guard !command.isEmpty else { return }
        
        isExecuting = true
        
        // Add command line to terminal
        let promptLine = "\(username)@\(hostname):\(currentDirectory)\(isRoot ? "#" : "$")"
        addPromptLine(promptLine)
        addCommandLine(command)
        
        do {
            let output = try await sshService.executeCommand(command, in: session)
            
            // Check if output contains errors
            let isError = containsError(output)
            
            // Add output lines
            let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
            for line in lines {
                let text = String(line)
                if isError && (text.lowercased().contains("error") || 
                              text.lowercased().contains("failed") ||
                              text.lowercased().contains("permission denied") ||
                              text.lowercased().contains("not found")) {
                    addErrorLine(text)
                } else if !text.isEmpty {
                    addOutputLine(text)
                }
            }
            
            // Update environment if directory changed
            if command.hasPrefix("cd ") || command == "cd" {
                await updateEnvironment()
            }
        } catch {
            addErrorLine("Error: \(error.localizedDescription)")
        }
        
        isExecuting = false
        
        // CRITICAL FIX: The view displays the current prompt separately,
        // so we don't add another prompt line here. The current input state
        // in EnhancedTerminalView will automatically show the new prompt.
        // The isExecuting = false above signals the view to re-enable input.
    }
    
    func clearScreen() async {
        terminalLines.removeAll()
    }
    
    private func formatDirectory(_ path: String) -> String {
        // For now, just use simple ~ replacement
        // Full home directory detection would require caching the home path
        if path.hasPrefix("/home/\(username)") {
            return path.replacingOccurrences(of: "/home/\(username)", with: "~")
        } else if path.hasPrefix("/root") && isRoot {
            return path.replacingOccurrences(of: "/root", with: "~")
        }
        return path
    }
    
    private func containsError(_ output: String) -> Bool {
        let lowercased = output.lowercased()
        return lowercased.contains("error") ||
               lowercased.contains("failed") ||
               lowercased.contains("permission denied") ||
               lowercased.contains("command not found") ||
               lowercased.contains("no such file")
    }
    
    private func addPromptLine(_ text: String) {
        terminalLines.append(TerminalLine(type: .prompt, text: text))
    }
    
    private func addCommandLine(_ text: String) {
        terminalLines.append(TerminalLine(type: .command, text: text))
    }
    
    private func addOutputLine(_ text: String) {
        terminalLines.append(TerminalLine(type: .output, text: text))
    }
    
    private func addErrorLine(_ text: String) {
        terminalLines.append(TerminalLine(type: .error, text: text))
    }
    
    private func addSystemLine(_ text: String) {
        terminalLines.append(TerminalLine(type: .system, text: text))
    }
    
    func executeCommand() async {
        guard !currentCommand.isEmpty else { return }
        
        isExecuting = true
        let command = currentCommand
        currentCommand = ""
        
        do {
            session.appendOutput("$ \(command)\n")
            _ = try await sshService.executeCommand(command, in: session)
        } catch {
            session.appendOutput("Error: \(error.localizedDescription)\n")
        }
        
        isExecuting = false
    }
    
    func sendInput(_ input: String) async {
        // Send raw input to SSH (for interactive terminal)
        guard !input.isEmpty else { return }
        
        do {
            _ = try await sshService.executeCommand(input.trimmingCharacters(in: .newlines), in: session)
        } catch {
            session.appendOutput("Error: \(error.localizedDescription)\n")
        }
    }
    
    func resizeTerminal(cols: Int, rows: Int) async {
        terminalSize = (cols, rows)
        // Future: send resize signal to SSH server
    }
    
    func clearPendingOutput() {
        // Clear after feeding to terminal
        pendingOutput = ""
    }
    
    func disconnect() async {
        await sshService.disconnect(session: session)
    }

    // MARK: - Buffer Management

    /// Trim terminal buffer if it exceeds the maximum
    private func trimBufferIfNeeded() {
        guard terminalLines.count > maxTerminalLines else { return }

        let excessLines = terminalLines.count - maxTerminalLines
        terminalLines.removeFirst(excessLines)
        totalLinesDropped += excessLines
        isBufferTruncated = true
    }

    /// Process large output efficiently by batching
    private func processLargeOutput(_ output: String) {
        let lines = output.components(separatedBy: "\n")

        // If output is massive, truncate with indicator
        if output.count > maxOutputBufferSize {
            addSystemLine("⚠️ Output truncated (exceeded \(maxOutputBufferSize / 1000)KB limit)")

            // Only show last portion
            let truncatedOutput = String(output.suffix(maxOutputBufferSize / 2))
            let truncatedLines = truncatedOutput.components(separatedBy: "\n")

            for (index, line) in truncatedLines.enumerated() {
                if !line.isEmpty {
                    // Check for errors
                    if containsError(line) {
                        addErrorLine(line)
                    } else {
                        addOutputLine(line)
                    }
                }

                // Allow UI updates periodically
                if index % lineBatchSize == 0 && index > 0 {
                    trimBufferIfNeeded()
                }
            }
        } else {
            // Normal output processing
            for (index, line) in lines.enumerated() {
                let text = String(line)
                if containsError(text) {
                    addErrorLine(text)
                } else if !text.isEmpty {
                    addOutputLine(text)
                }

                // Periodic buffer maintenance
                if index % lineBatchSize == 0 && index > 0 {
                    trimBufferIfNeeded()
                }
            }
        }

        trimBufferIfNeeded()
    }

    /// Get terminal statistics
    func getBufferStats() -> (lineCount: Int, truncated: Bool, droppedLines: Int) {
        return (terminalLines.count, isBufferTruncated, totalLinesDropped)
    }

    /// Clear buffer and reset statistics
    func resetBuffer() {
        terminalLines.removeAll()
        isBufferTruncated = false
        totalLinesDropped = 0
    }

    /// Export terminal history
    func exportHistory() -> String {
        var export = "# SSH Terminal Session Export\n"
        export += "# Host: \(hostname)\n"
        export += "# Date: \(Date().formatted())\n"
        export += "# Lines: \(terminalLines.count)\n"
        if isBufferTruncated {
            export += "# Note: \(totalLinesDropped) lines were truncated\n"
        }
        export += "#\n\n"

        for line in terminalLines {
            switch line.type {
            case .prompt:
                export += line.text
            case .command:
                export += " \(line.text)\n"
            case .output, .system:
                export += "\(line.text)\n"
            case .error:
                export += "[ERROR] \(line.text)\n"
            }
        }

        return export
    }
}

