import SwiftUI
@preconcurrency import SwiftTerm
@preconcurrency import Citadel
import NIOCore
import NIOSSH
import UIKit
import AudioToolbox

struct PTYTerminalView: UIViewRepresentable {
    typealias UIViewType = SwiftTerm.TerminalView

    let client: SSHClient
    @Binding var isConnected: Bool

    enum Event: Sendable {
        case send(ByteBuffer)
        case changeSize(cols: Int, rows: Int)
    }

    final class Coordinator: NSObject, TerminalViewDelegate, @unchecked Sendable {
        // Use nonisolated(unsafe) for non-Sendable Citadel type
        nonisolated(unsafe) let client: SSHClient
        nonisolated(unsafe) var terminalView: SwiftTerm.TerminalView?
        private let events = AsyncStream<Event>.makeStream()
        let isConnected: Binding<Bool>
        private var connectionTask: Task<Void, Never>?

        // Track initial terminal size
        private var initialCols: Int = 80
        private var initialRows: Int = 24

        init(client: SSHClient, isConnected: Binding<Bool>) {
            self.client = client
            self.isConnected = isConnected
            super.init()
        }

        deinit {
            connectionTask?.cancel()
            events.continuation.finish()
        }

        func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
            guard newCols > 0, newRows > 0 else { return }
            // Update stored size for initial PTY request
            initialCols = newCols
            initialRows = newRows
            events.continuation.yield(.changeSize(cols: newCols, rows: newRows))
        }

        func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {}

        func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
            events.continuation.yield(.send(ByteBuffer(bytes: data)))
        }

        func scrolled(source: SwiftTerm.TerminalView, position: Double) {}
        func clipboardCopy(source: SwiftTerm.TerminalView, content: Data) {}
        func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {}
        func requestOpenLink(source: SwiftTerm.TerminalView, link: String, params: [String: String]) {}

        func bell(source: SwiftTerm.TerminalView) {
            // Provide haptic feedback for bell
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }

        func iTermContent(source: SwiftTerm.TerminalView, content: ArraySlice<UInt8>) {}

        func startConnection() {
            connectionTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.run()
                } catch {
                    print("❌ PTY connection error: \(error)")
                    await MainActor.run {
                        self.isConnected.wrappedValue = false
                    }
                }
            }
        }

        func run() async throws {
            // Use reasonable default dimensions instead of 0
            let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
                wantReply: true,
                term: "xterm-256color",
                terminalCharacterWidth: initialCols,
                terminalRowHeight: initialRows,
                terminalPixelWidth: 0,
                terminalPixelHeight: 0,
                terminalModes: SSHTerminalModes([.ECHO: 1])
            )

            try await client.withPTY(ptyRequest) { inbound, outbound in
                try await withThrowingTaskGroup(of: Void.self) { group in
                    // Task for receiving output from SSH server
                    group.addTask { [weak self] in
                        guard let self = self else { return }
                        for try await input in inbound {
                            switch input {
                            case .stdout(var buf), .stderr(var buf):
                                if let bytes = buf.readBytes(length: buf.readableBytes) {
                                    await MainActor.run {
                                        self.terminalView?.feed(byteArray: bytes[...])
                                    }
                                }
                            }
                        }
                    }

                    // Task for sending user input to SSH server
                    group.addTask { [weak self] in
                        guard let self = self else { return }
                        for await event in self.events.stream {
                            switch event {
                            case .send(let buffer):
                                try await outbound.write(buffer)
                            case .changeSize(let cols, let rows):
                                try await outbound.changeSize(
                                    cols: cols,
                                    rows: rows,
                                    pixelWidth: 0,
                                    pixelHeight: 0
                                )
                            }
                        }
                    }

                    try await group.waitForAll()
                }
            }
        }
    }

    func makeUIView(context: Context) -> SwiftTerm.TerminalView {
        let tv = SwiftTerm.TerminalView(frame: .zero)
        tv.terminalDelegate = context.coordinator
        tv.nativeForegroundColor = UIColor.label
        tv.nativeBackgroundColor = UIColor.systemBackground
        context.coordinator.terminalView = tv

        // Start connection after a brief delay to allow terminal to size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.coordinator.startConnection()
        }

        return tv
    }

    func updateUIView(_ uiView: SwiftTerm.TerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(client: client, isConnected: $isConnected)
    }
}
