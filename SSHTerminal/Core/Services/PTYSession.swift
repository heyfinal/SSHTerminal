//
//  PTYSession.swift
//  SSHTerminal
//
//  Manages a persistent PTY (pseudo-terminal) session with proper dimensions
//

import Foundation
import NIO
import NIOSSH
@preconcurrency import Citadel

/// Manages a persistent interactive shell with PTY for proper terminal behavior
/// The Citadel types (SSHClient, TTYStdinWriter, Channel) are not Sendable but are
/// safe to use here because:
/// 1. They're only created/accessed from async contexts within this class
/// 2. We use @unchecked Sendable because we manually ensure thread-safety
final class PTYSession: @unchecked Sendable {
    // These are set once and never changed (immutable after init)
    private let session: SSHSession
    private nonisolated(unsafe) let client: SSHClient

    // These are mutable but protected by being only accessed after channel setup
    private nonisolated(unsafe) var channel: Channel?
    private nonisolated(unsafe) var writer: TTYStdinWriter?
    private var outputHandler: (@Sendable (Data) -> Void)?
    private var streamTask: Task<Void, Never>?

    private(set) var terminalSize: (cols: Int, rows: Int)
    @MainActor private(set) var isActive = false

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
        let (channel, stream) = try await client._executeCommandStream(
            environment: [],
            mode: .pty(ptyRequest)
        )

        self.channel = channel
        self.writer = TTYStdinWriter(channel: channel)
        await MainActor.run { self.isActive = true }

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
                        self.handleOutput(Data(buffer: buffer))
                    case .stderr(let buffer):
                        self.handleOutput(Data(buffer: buffer))
                    }
                }
                await self.setInactive()
                print("📤 PTY stream ended normally")
            } catch {
                await self.setInactive()
                print("❌ PTY stream error: \(error)")
            }
        }
    }

    private func handleOutput(_ data: Data) {
        outputHandler?(data)
    }

    @MainActor
    private func setInactive() {
        isActive = false
    }

    /// Send data to the PTY (user input)
    func write(_ data: Data) async throws {
        let active = await MainActor.run { isActive }
        guard active, let writer = writer else {
            throw PTYError.notActive
        }

        var buffer = ByteBuffer()
        buffer.writeBytes(data)
        try await writer.write(buffer)
    }

    /// Resize the PTY terminal dimensions
    func resize(cols: Int, rows: Int) async throws {
        let active = await MainActor.run { isActive }
        guard active, let writer = writer else { return }

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
        await MainActor.run { isActive = false }

        if let channel = channel {
            try? await channel.close()
        }

        channel = nil
        writer = nil
    }
}

enum PTYError: Error, LocalizedError {
    case notActive
    case channelCreationFailed

    var errorDescription: String? {
        switch self {
        case .notActive:
            return "PTY session is not active"
        case .channelCreationFailed:
            return "Failed to create PTY channel"
        }
    }
}
