import SwiftUI

struct ServerListView: View {
    @StateObject private var viewModel = ServerListViewModel()
    @State private var serverToConnect: ServerProfile?
    @State private var connectionPassword = ""
    @State private var showPasswordPrompt = false
    @State private var showScanSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.servers.isEmpty {
                        emptyStateView
                    } else {
                        serverListView
                    }
                }
            }
            .navigationTitle("SSH Servers")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showScanSheet = true
                    } label: {
                        Image(systemName: "wifi.router")
                            .foregroundColor(.cyan)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddServerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingEditSheet) {
                if let server = viewModel.serverToEdit {
                    EditServerView(viewModel: viewModel, server: server)
                }
            }
            .sheet(isPresented: $showScanSheet) {
                NetworkScanView(serverViewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedServer) { server in
                if let session = SSHService.shared.activeSessions.values.first(where: { $0.server.id == server.id }) {
                    TerminalView(session: session)
                }
            }
            .alert("Connect to Server", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $connectionPassword)
                Button("Cancel", role: .cancel) {
                    serverToConnect = nil
                    connectionPassword = ""
                }
                Button("Connect") {
                    if let server = serverToConnect {
                        Task {
                            await viewModel.connectToServer(server, password: connectionPassword)
                            connectionPassword = ""
                            serverToConnect = nil
                        }
                    }
                }
            } message: {
                if let server = serverToConnect {
                    Text("Enter password for \(server.username)@\(server.host)")
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Servers")
                .font(.title2)
                .foregroundColor(.white)

            Text("Add a server manually or scan your network")
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                Button {
                    viewModel.isShowingAddSheet = true
                } label: {
                    Label("Add Server", systemImage: "plus")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button {
                    showScanSheet = true
                } label: {
                    Label("Scan Network", systemImage: "wifi.router")
                        .padding()
                        .background(Color.cyan.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var serverListView: some View {
        List {
            ForEach(viewModel.servers) { server in
                ServerRowView(
                    server: server,
                    hasSavedPassword: server.savedPassword,
                    onConnect: {
                        if viewModel.needsPasswordPrompt(for: server) {
                            serverToConnect = server
                            showPasswordPrompt = true
                        } else {
                            Task { await viewModel.connectToServer(server) }
                        }
                    },
                    onEdit: {
                        viewModel.serverToEdit = server
                        viewModel.isShowingEditSheet = true
                    },
                    onDelete: {
                        viewModel.deleteServer(server)
                    }
                )
                .listRowBackground(Color.black)
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    viewModel.deleteServer(viewModel.servers[index])
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Server Row

struct ServerRowView: View {
    let server: ServerProfile
    let hasSavedPassword: Bool
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text(server.displayAddress)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if hasSavedPassword {
                        Image(systemName: "key.fill")
                            .font(.caption)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                }

                if let lastConnected = server.lastConnectedAt {
                    Text("Last: \(lastConnected.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.green.opacity(0.7))
                }
            }

            Spacer()

            Button(action: onConnect) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

// MARK: - Add Server

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ServerListViewModel

    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var password = ""
    @State private var savePassword = false
    @State private var authType = AuthType.password

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Authentication") {
                    Picker("Auth Type", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }

                    if authType == .password {
                        SecureField("Password", text: $password)
                        if !password.isEmpty {
                            Toggle("Save Password", isOn: $savePassword)
                        }
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
                    Button("Save") { saveServer() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty && Int(port) != nil
    }

    private func saveServer() {
        let server = ServerProfile(
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authType: authType,
            savedPassword: savePassword && !password.isEmpty
        )
        viewModel.addServer(server)

        if savePassword && !password.isEmpty {
            try? KeychainService.shared.save(password: password, for: server.passwordKeychainKey)
        }

        dismiss()
    }
}

// MARK: - Edit Server

struct EditServerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ServerListViewModel
    let server: ServerProfile

    @State private var name = ""
    @State private var host = ""
    @State private var port = ""
    @State private var username = ""
    @State private var password = ""
    @State private var savePassword = false
    @State private var authType = AuthType.password

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Authentication") {
                    Picker("Auth Type", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }

                    if authType == .password {
                        if server.savedPassword {
                            HStack {
                                Text("Saved Password")
                                Spacer()
                                Button("Remove") {
                                    viewModel.deletePassword(for: server)
                                    savePassword = false
                                    password = ""
                                }
                                .foregroundColor(.red)
                                .font(.callout)
                            }
                        }

                        SecureField(server.savedPassword ? "Change Password" : "Password", text: $password)

                        if !password.isEmpty {
                            Toggle("Save Password", isOn: $savePassword)
                        }
                    }
                }

                Section("Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Created")
                            .font(.caption).foregroundColor(.gray)
                        Text(server.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)

                        if let lastConnected = server.lastConnectedAt {
                            Divider()
                            Text("Last Connected")
                                .font(.caption).foregroundColor(.gray)
                            Text(lastConnected.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Edit Server")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { updateServer() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                name = server.name
                host = server.host
                port = String(server.port)
                username = server.username
                authType = server.authType
                savePassword = server.savedPassword
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty && Int(port) != nil
    }

    private func updateServer() {
        var updatedServer = server
        updatedServer.name = name
        updatedServer.host = host
        updatedServer.port = Int(port) ?? 22
        updatedServer.username = username
        updatedServer.authType = authType

        if savePassword && !password.isEmpty {
            try? KeychainService.shared.save(password: password, for: server.passwordKeychainKey)
            updatedServer.savedPassword = true
        } else if !savePassword && server.savedPassword && password.isEmpty {
            // Preserve existing saved password if user didn't touch the field
            updatedServer.savedPassword = server.savedPassword
        }

        viewModel.updateServer(updatedServer)
        dismiss()
    }
}
