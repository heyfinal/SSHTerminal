import SwiftUI

struct NetworkScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = NetworkScannerService.shared
    @ObservedObject var serverViewModel: ServerListViewModel

    @State private var hostToAdd: DiscoveredHost?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status bar
                    statusBar

                    Divider().background(Color.gray.opacity(0.3))

                    if scanner.discoveredHosts.isEmpty && !scanner.isScanning {
                        emptyState
                    } else {
                        hostList
                    }
                }
            }
            .navigationTitle("Network Scan")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.green)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if scanner.isScanning {
                        Button("Stop") { scanner.stopScan() }
                            .foregroundColor(.red)
                    } else {
                        Button("Scan") { scanner.startScan() }
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                if let host = hostToAdd {
                    QuickAddServerView(host: host, viewModel: serverViewModel)
                }
            }
            .onAppear {
                if !scanner.isScanning && scanner.discoveredHosts.isEmpty {
                    scanner.startScan()
                }
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            if scanner.isScanning {
                ProgressView(value: scanner.progress)
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .frame(maxWidth: .infinity)

                Text("\(scanner.scannedCount)/254")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.gray)
            } else if !scanner.discoveredHosts.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("\(scanner.discoveredHosts.count) SSH host\(scanner.discoveredHosts.count == 1 ? "" : "s") found")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                Image(systemName: "wifi")
                    .foregroundColor(.gray)
                Text(scanner.localIPAddress().map { "Network: \($0)" } ?? "No network")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "network.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No SSH servers found")
                .font(.headline)
                .foregroundColor(.white)
            Text("Tap Scan to search your local network for hosts with port 22 open.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Host List

    private var hostList: some View {
        List {
            ForEach(scanner.discoveredHosts) { host in
                DiscoveredHostRow(host: host) {
                    hostToAdd = host
                    showAddSheet = true
                }
                .listRowBackground(Color.black)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Row

private struct DiscoveredHostRow: View {
    let host: DiscoveredHost
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(host.ip)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white)
                if let name = host.hostname {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("SSH")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Add Sheet

struct QuickAddServerView: View {
    @Environment(\.dismiss) private var dismiss
    let host: DiscoveredHost
    @ObservedObject var viewModel: ServerListViewModel

    @State private var name: String
    @State private var username = ""
    @State private var port = "22"
    @State private var password = ""
    @State private var savePassword = false

    init(host: DiscoveredHost, viewModel: ServerListViewModel) {
        self.host = host
        self.viewModel = viewModel
        _name = State(initialValue: host.hostname ?? host.ip)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    HStack {
                        Text("Host")
                        Spacer()
                        Text(host.ip)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                    TextField("Name", text: $name)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }

                Section("Credentials") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password (optional)", text: $password)

                    if !password.isEmpty {
                        Toggle("Save Password", isOn: $savePassword)
                    }
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addServer() }
                        .disabled(username.isEmpty)
                }
            }
        }
    }

    private func addServer() {
        let server = ServerProfile(
            name: name.isEmpty ? host.ip : name,
            host: host.ip,
            port: Int(port) ?? 22,
            username: username,
            authType: .password,
            savedPassword: savePassword && !password.isEmpty
        )
        viewModel.addServer(server)

        if savePassword && !password.isEmpty {
            try? KeychainService.shared.save(password: password, for: "ssh_pwd_\(server.id.uuidString)")
        }

        dismiss()
    }
}
