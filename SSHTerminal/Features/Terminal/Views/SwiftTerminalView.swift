//
//  SwiftTerminalView.swift
//  SSHTerminal
//
//  Proper terminal emulation using SwiftTerm library
//  This provides a unified terminal experience like a real terminal app
//

import SwiftUI
import SwiftTerm

/// SwiftUI wrapper for SwiftTerm's native TerminalView
/// Provides a real terminal emulation experience with proper PTY support
struct SwiftTerminalView: UIViewRepresentable {
    @ObservedObject var viewModel: TerminalViewModel

    func makeUIView(context: Context) -> TerminalView {
        let terminalView = TerminalView(frame: .zero)

        // Configure terminal appearance
        terminalView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        terminalView.nativeForegroundColor = UIColor.white
        terminalView.nativeBackgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)

        // Set up fonts with precise sizing
        let fontSize: CGFloat = 14
        terminalView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Configure terminal options
        terminalView.optionAsMetaKey = true
        terminalView.allowMouseReporting = false
        
        // Ensure proper content alignment and layout
        terminalView.contentMode = .topLeft
        terminalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Set the delegate
        terminalView.terminalDelegate = context.coordinator

        // Store reference for data feeding
        context.coordinator.terminalView = terminalView

        // Connect to the view model
        viewModel.terminalView = terminalView
        viewModel.coordinator = context.coordinator
        
        // Set initial terminal size (will be updated when view gets proper frame)
        terminalView.resize(cols: 80, rows: 24)
        
        // Start the session
        viewModel.startSession()
        
        // Force layout update after a brief delay to ensure proper sizing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if terminalView.bounds.size.width > 0 {
                viewModel.updateTerminalSize(terminalView)
            }
        }

        return terminalView
    }

    func updateUIView(_ uiView: TerminalView, context: Context) {
        // Update terminal size whenever the view bounds change
        DispatchQueue.main.async {
            viewModel.updateTerminalSize(uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        var viewModel: SwiftTerminalViewModel
        nonisolated(unsafe) weak var terminalView: TerminalView?

        init(viewModel: SwiftTerminalViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - TerminalViewDelegate

        nonisolated func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            let vm = viewModel
            Task { @MainActor in
                vm.terminalSizeChanged(cols: newCols, rows: newRows)
            }
        }

        nonisolated func setTerminalTitle(source: TerminalView, title: String) {
            let vm = viewModel
            Task { @MainActor in
                vm.terminalTitle = title
            }
        }

        nonisolated func send(source: TerminalView, data: ArraySlice<UInt8>) {
            // User typed something - send to SSH
            let vm = viewModel
            Task { @MainActor in
                vm.sendToSSH(data: data)
            }
        }

        nonisolated func scrolled(source: TerminalView, position: Double) {
            // Handle scroll position changes if needed
        }

        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            if let dir = directory {
                let vm = viewModel
                Task { @MainActor in
                    vm.currentDirectory = dir
                }
            }
        }

        nonisolated func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
            if let url = URL(string: link) {
                Task { @MainActor in
                    UIApplication.shared.open(url)
                }
            }
        }

        nonisolated func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
            // Range selection changed
        }

        nonisolated func clipboardCopy(source: TerminalView, content: Data) {
            if let text = String(data: content, encoding: .utf8) {
                Task { @MainActor in
                    UIPasteboard.general.string = text
                }
            }
        }

        nonisolated func bell(source: TerminalView) {
            // Play bell sound or haptic
            Task { @MainActor in
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }
}
