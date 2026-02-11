//
//  ServerListView.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import SwiftUI

struct ServerListView: View {
    @StateObject private var viewModel = ServerListViewModel()
    @State private var serverToConnect: ServerProfile?
    @State private var connectionPassword = ""
    @State private var showPasswordPrompt = false
    
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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
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
            
            Text("Add a server to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button {
                viewModel.isShowingAddSheet = true
            } label: {
                Label("Add Server", systemImage: "plus")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var serverListView: some View {
        List {
            ForEach(viewModel.servers) { server in
                ServerRowView(
                    server: server,
                    onConnect: {
                        serverToConnect = server
                        showPasswordPrompt = true
                    },
                    onEdit: {
                        // TODO: Implement edit
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

struct ServerRowView: View {
    let server: ServerProfile
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(server.displayAddress)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let lastConnected = server.lastConnectedAt {
                    Text("Last: \(lastConnected.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.green.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button {
                onConnect()
            } label: {
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

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ServerListViewModel
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var authType = AuthType.password
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    TextField("Username", text: $username)
                }
                
                Section("Authentication") {
                    Picker("Auth Type", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveServer()
                    }
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
            authType: authType
        )
        
        viewModel.addServer(server)
        dismiss()
    }
}
