import SwiftUI
import AudioToolbox
import Citadel

struct TerminalView: View {
    @Environment(\.dismiss) private var dismiss
    let session: SSHSession
    @State private var sshClient: SSHClient?
    @State private var isConnected = false
    @State private var showingSettings = false
    @State private var showingError = false
    @State private var errorMessage: String?

    // Autocomplete
    @StateObject private var autocomplete = BashAutocompleteService.shared
    @State private var injectIntoPTY: (([UInt8]) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let client = sshClient, isConnected {
                        // Autocomplete suggestion bar (only visible when suggestions exist)
                        AutocompleteBarView(autocomplete: autocomplete) { bytes in
                            injectIntoPTY?(bytes)
                        }

                        // Native SwiftTerm PTY
                        PTYTerminalView(
                            client: client,
                            isConnected: $isConnected,
                            onUserInput: { bytes in
                                Task { @MainActor in
                                    BashAutocompleteService.shared.processInputBytes(bytes)
                                }
                            },
                            injectSink: { sink in
                                injectIntoPTY = sink
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 20) {
                            ProgressView()
                            Text("Connecting to \(session.server.host)...")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle(session.server.name)
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    connectionStatusView
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingSettings = true } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        Divider()
                        Button(role: .destructive) {
                            isConnected = false
                            dismiss()
                        } label: {
                            Label("Disconnect", systemImage: "xmark.circle.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                TerminalSettingsView(settings: .constant(TerminalSettings()))
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK") { dismiss() }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .task {
                await connectToSSH()
            }
            .onChange(of: isConnected) { _, connected in
                if !connected {
                    autocomplete.clearBuffer()
                    dismiss()
                }
            }
            .onDisappear {
                autocomplete.clearBuffer()
                autocomplete.activeSession = nil
            }
        }
    }

    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? .green : .yellow)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Connected" : "Connecting")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func connectToSSH() async {
        do {
            guard let client = await SSHService.shared.getClient(for: session) else {
                throw SSHError.connectionFailed("No SSH client available")
            }
            await MainActor.run {
                self.sshClient = client
                self.isConnected = true
                BashAutocompleteService.shared.activeSession = session
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showingError = true
            }
        }
    }
}
