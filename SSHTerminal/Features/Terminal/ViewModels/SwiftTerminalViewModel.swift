//
//  SwiftTerminalViewModel.swift
//  SSHTerminal
//
//  ViewModel for SwiftTerm integration with PTY
//

import Foundation
import SwiftUI
import Citadel
import NIO

@MainActor
class SwiftTerminalViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var terminalSize: (cols: Int, rows: Int) = (80, 24)

    let session: SSHSession
    
    // Callback to feed data to the terminal view (set by SwiftTerminalView)
    var feedToTerminal: ((Data) -> Void)?

    private let sshService = SSHService.shared
    private var ptySession: PTYSession?

    init(session: SSHSession) {
        self.session = session
    }

    func sendInput(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        try? await ptySession?.write(data)
    }
    
    func sendToSSH(data: ArraySlice<UInt8>) {
        Task {
            try? await ptySession?.write(Data(data))
        }
    }

    func terminalSizeChanged(cols: Int, rows: Int) {
        guard cols != terminalSize.cols || rows != terminalSize.rows else { return }
        
        print("📐 Terminal resize: \(cols)x\(rows)")
        terminalSize = (cols, rows)
        
        Task {
            try? await ptySession?.resize(cols: cols, rows: rows)
        }
    }

    func startSession() {
        isConnected = session.state == .connected

        if isConnected {
            Task {
                do {
                    // Create PTY session with current terminal dimensions
                    let pty = try sshService.createPTYSession(
                        for: session,
                        terminalSize: terminalSize
                    )
                    
                    // Start the PTY and handle output
                    try await pty.start { [weak self] data in
                        Task { @MainActor in
                            self?.feedToTerminal?(data)
                        }
                    }
                    
                    ptySession = pty
                    print("✅ PTY session started with dimensions: \(terminalSize)")
                    
                } catch {
                    let errorMsg = "\r\n\u{001B}[31mFailed to start PTY: \(error.localizedDescription)\u{001B}[0m\r\n"
                    feedToTerminal?(errorMsg.data(using: .utf8) ?? Data())
                }
            }
        }
    }

    func disconnect() async {
        await ptySession?.close()
        ptySession = nil
        await sshService.disconnect(session: session)
        isConnected = false
        let msg = "\r\n\u{001B}[33m✓ Disconnected\u{001B}[0m\r\n"
        feedToTerminal?(msg.data(using: .utf8) ?? Data())
    }
}
