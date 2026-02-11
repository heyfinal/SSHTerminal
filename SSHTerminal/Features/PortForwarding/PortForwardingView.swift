//
//  PortForwardingView.swift
//  SSHTerminal
//
//  Phase 5: Port Forwarding Management UI
//

import SwiftUI

struct PortForwardingView: View {
    @StateObject private var service = PortForwardService()
    @State private var showingAddTunnel = false
    @State private var editingTunnel: PortForwardTunnel?
    
    let session: SSHSession
    
    var body: some View {
        NavigationView {
            List {
                if service.tunnels.isEmpty {
                    emptyState
                } else {
                    ForEach(service.tunnels) { tunnel in
                        TunnelRowView(tunnel: tunnel, service: service)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await service.deleteTunnel(tunnel)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingTunnel = tunnel
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Port Forwarding")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTunnel = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTunnel) {
                TunnelEditorView(service: service, session: session)
            }
            .sheet(item: $editingTunnel) { tunnel in
                TunnelEditorView(service: service, session: session, editingTunnel: tunnel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Port Forwards")
                .font(.headline)
            
            Text("Create tunnels to forward ports between your device and the remote server")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Add Tunnel") {
                showingAddTunnel = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Tunnel Row

struct TunnelRowView: View {
    let tunnel: PortForwardTunnel
    @ObservedObject var service: PortForwardService
    @State private var isToggling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tunnel.name)
                        .font(.headline)
                    
                    Text(tunnel.displayDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isToggling {
                    ProgressView()
                } else {
                    Toggle("", isOn: Binding(
                        get: { tunnel.isActive },
                        set: { isActive in
                            Task {
                                await toggleTunnel(isActive)
                            }
                        }
                    ))
                    .labelsHidden()
                }
            }
            
            HStack(spacing: 12) {
                Label(tunnel.type.rawValue, systemImage: typeIcon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                if tunnel.isActive {
                    Label("Active", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var typeIcon: String {
        switch tunnel.type {
        case .local: return "arrow.right"
        case .remote: return "arrow.left"
        case .dynamic: return "arrow.left.arrow.right"
        }
    }
    
    private func toggleTunnel(_ isActive: Bool) async {
        isToggling = true
        
        do {
            if isActive {
                try await service.startForwarding(tunnel)
            } else {
                await service.stopForwarding(tunnel)
            }
        } catch {
            // Show error
            print("Toggle failed: \(error)")
        }
        
        isToggling = false
    }
}

// MARK: - Tunnel Editor

struct TunnelEditorView: View {
    @ObservedObject var service: PortForwardService
    let session: SSHSession
    var editingTunnel: PortForwardTunnel?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var type: PortForwardType
    @State private var localPort: String
    @State private var remoteHost: String
    @State private var remotePort: String
    @State private var errorMessage: String?
    
    init(service: PortForwardService, session: SSHSession, editingTunnel: PortForwardTunnel? = nil) {
        self.service = service
        self.session = session
        self.editingTunnel = editingTunnel
        
        _name = State(initialValue: editingTunnel?.name ?? "")
        _type = State(initialValue: editingTunnel?.type ?? .local)
        _localPort = State(initialValue: editingTunnel?.localPort.description ?? "")
        _remoteHost = State(initialValue: editingTunnel?.remoteHost ?? "localhost")
        _remotePort = State(initialValue: editingTunnel?.remotePort.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tunnel Information") {
                    TextField("Name", text: $name)
                        .autocapitalization(.none)
                    
                    Picker("Type", selection: $type) {
                        ForEach(PortForwardType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Local Configuration") {
                    HStack {
                        Text("Port:")
                        TextField("8080", text: $localPort)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if type != .dynamic {
                    Section("Remote Configuration") {
                        TextField("Host", text: $remoteHost)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        HStack {
                            Text("Port:")
                            TextField("80", text: $remotePort)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    exampleText
                }
            }
            .navigationTitle(editingTunnel == nil ? "New Tunnel" : "Edit Tunnel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTunnel()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var exampleText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Example:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(exampleDescription)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
    
    private var exampleDescription: String {
        let local = Int(localPort) ?? 8080
        let remote = Int(remotePort) ?? 80
        
        switch type {
        case .local:
            return "Access \(remoteHost):\(remote) via localhost:\(local)"
        case .remote:
            return "Access localhost:\(local) via server:\(remote)"
        case .dynamic:
            return "SOCKS proxy on localhost:\(local)"
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        Int(localPort) != nil &&
        (type == .dynamic || (!remoteHost.isEmpty && Int(remotePort) != nil))
    }
    
    private func saveTunnel() {
        guard let localP = Int(localPort) else { return }
        let remoteP = Int(remotePort) ?? 80
        
        let tunnel = PortForwardTunnel(
            id: editingTunnel?.id ?? UUID(),
            name: name,
            type: type,
            localPort: localP,
            remoteHost: type == .dynamic ? "localhost" : remoteHost,
            remotePort: remoteP
        )
        
        if let error = service.validateTunnel(tunnel) {
            errorMessage = error
            return
        }
        
        if editingTunnel != nil {
            service.updateTunnel(tunnel)
        } else {
            service.addTunnel(tunnel)
        }
        
        dismiss()
    }
}
