//
//  PTYSession.swift
//  SSHTerminal
//
//  Manages a persistent PTY (pseudo-terminal) session with proper dimensions
//

import Foundation
import NIO
import NIOSSH
import Citadel

/// Manages a persistent interactive shell with PTY for proper terminal behavior
actor PTYSession {
    nonisolated(unsafe) private let session: SSHSession
    nonisolated(unsafe) private let client: SSHClient
    nonisolated(unsafe) private var channel: Channel?
    nonisolated(unsafe) private var writer: TTYStdinWriter?
    private var outputHandler: (@Sendable (Data) -> Void)?
    private var streamTask: Task<Void, Never>?
    
    private(set) var terminalSize: (cols: Int, rows: Int)
    private(set) var isActive = false
    
    init(session: SSHSession, client: SSHClient, terminalSize: (cols: Int, rows: Int)) {
        self.session = session
        self.client = client
        self.terminalSize = terminalSize
    }
    
    /// Start the PTY session with proper terminal dimensions
    func start(onOutput: @escaping @Sendable (Data) -> Void) async throws {
        self.outputHandler = onOutput
        
        print("🔧 Starting PTY session with dimensions: \(terminalSize.cols)x\(terminalSize.rows)")
        
        // Create PTY request with terminal dimensions
        let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: false,
            term: "xterm-256color",
            terminalCharacterWidth: terminalSize.cols,
            terminalRowHeight: terminalSize.rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: SSHTerminalModes([:])
        )
        
        // Use the newly exposed _executeCommandStream with PTY mode
        // Note: SSHClient isn't Sendable but is used within actor isolation
        let (channel, stream) = try await client._executeCommandStream(
            environment: [],
            mode: .pty(ptyRequest)
        )
        
        self.channel = channel
        self.writer = TTYStdinWriter(channel: channel)
        self.isActive = true
        
        print("✅ PTY session active, starting shell...")
        
        // Request shell after PTY is allocated
        try await channel.triggerUserOutboundEvent(
            SSHChannelRequestEvent.ShellRequest(wantReply: true)
        )
        
        // Process output in background task
        streamTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                for try await output in stream {
                    switch output {
                    case .stdout(let buffer):
                        await self.handleOutput(Data(buffer: buffer))
                    case .stderr(let buffer):
                        await self.handleOutput(Data(buffer: buffer))
                    }
                }
                await self.markInactive()
                print("📤 PTY stream ended normally")
            } catch {
                await self.markInactive()
                print("❌ PTY stream error: \(error)")
            }
        }
    }
    
    private func handleOutput(_ data: Data) {
        outputHandler?(data)
    }
    
    private func markInactive() {
        isActive = false
    }
    
    /// Send data to the PTY (user input)
    func write(_ data: Data) async throws {
        guard isActive, let writer = writer else {
            throw PTYError.notActive
        }
        
        var buffer = ByteBuffer()
        buffer.writeBytes(data)
        try await writer.write(buffer)
    }
    
    /// Resize the PTY terminal dimensions
    func resize(cols: Int, rows: Int) async throws {
        guard isActive, let writer = writer else { return }
        
        self.terminalSize = (cols, rows)
        print("📐 Resizing PTY to: \(cols)x\(rows)")
        
        try await writer.changeSize(
            cols: cols,
            rows: rows,
            pixelWidth: 0,
            pixelHeight: 0
        )
    }
    
    /// Close the PTY session
    func close() async {
        streamTask?.cancel()
        streamTask = nil
        isActive = false
        
        if let channel = channel {
            try? await channel.close()
        }
        
        channel = nil
        writer = nil
    }
}

enum PTYError: Error {
    case notActive
    case channelCreationFailed
}
