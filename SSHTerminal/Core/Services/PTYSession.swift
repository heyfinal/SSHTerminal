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

/// Manages a persistent interactive shell with PTY for proper terminal behavior.
/// Actor isolation ensures all mutable state access is serialized.
actor PTYSession {
    private let session: SSHSession
    private nonisolated let client: SSHClient

    private var channel: Channel?
    private var writer: TTYStdinWriter?
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

        let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: false,
            term: "xterm-256color",
            terminalCharacterWidth: terminalSize.cols,
            terminalRowHeight: terminalSize.rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: SSHTerminalModes([:])
        )

        let (channel, stream) = try await client._executeCommandStream(
            environment: [],
            mode: .pty(ptyRequest)
        )

        self.channel = channel
        self.writer = TTYStdinWriter(channel: channel)
        self.isActive = true

        try await channel.triggerUserOutboundEvent(
            SSHChannelRequestEvent.ShellRequest(wantReply: true)
        )

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
                await self.setInactive()
            } catch {
                await self.setInactive()
            }
        }
    }

    private func handleOutput(_ data: Data) {
        outputHandler?(data)
    }

    private func setInactive() {
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
