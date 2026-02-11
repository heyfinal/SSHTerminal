//
//  PortForwardService.swift
//  SSHTerminal
//
//  Phase 5: SSH Port Forwarding Management
//

import Foundation
import Citadel
import NIO

enum PortForwardError: Error {
    case notImplemented
    case operationFailed(String)
}

enum PortForwardType: String, Codable, CaseIterable {
    case local = "Local (-L)"
    case remote = "Remote (-R)"
    case dynamic = "Dynamic (SOCKS)"
    
    var description: String {
        switch self {
        case .local: return "Forward local port to remote"
        case .remote: return "Forward remote port to local"
        case .dynamic: return "SOCKS proxy"
        }
    }
}

struct PortForwardTunnel: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: PortForwardType
    var localPort: Int
    var remoteHost: String
    var remotePort: Int
    var isActive: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        type: PortForwardType,
        localPort: Int,
        remoteHost: String = "localhost",
        remotePort: Int,
        isActive: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.localPort = localPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    var displayDescription: String {
        switch type {
        case .local:
            return "localhost:\(localPort) → \(remoteHost):\(remotePort)"
        case .remote:
            return "\(remoteHost):\(remotePort) → localhost:\(localPort)"
        case .dynamic:
            return "SOCKS proxy on localhost:\(localPort)"
        }
    }
}

@MainActor
class PortForwardService: ObservableObject {
    @Published var tunnels: [PortForwardTunnel] = []
    @Published var activeTunnels: Set<UUID> = []
    
    private var forwardedPorts: [UUID: Any] = [:] // Store port forward objects
    private weak var sshClient: SSHClient?
    
    init() {
        loadTunnels()
    }
    
    // MARK: - Tunnel Management
    
    func addTunnel(_ tunnel: PortForwardTunnel) {
        tunnels.append(tunnel)
        saveTunnels()
    }
    
    func updateTunnel(_ tunnel: PortForwardTunnel) {
        if let index = tunnels.firstIndex(where: { $0.id == tunnel.id }) {
            tunnels[index] = tunnel
            saveTunnels()
        }
    }
    
    func deleteTunnel(_ tunnel: PortForwardTunnel) async {
        if tunnel.isActive {
            await stopForwarding(tunnel)
        }
        tunnels.removeAll { $0.id == tunnel.id }
        saveTunnels()
    }
    
    // MARK: - Port Forwarding Operations
    
    func setSSHClient(_ client: SSHClient) {
        self.sshClient = client
    }
    
    func startForwarding(_ tunnel: PortForwardTunnel) async throws {
        guard let client = sshClient else {
            throw SSHError.disconnected
        }
        
        do {
            switch tunnel.type {
            case .local:
                try await startLocalForward(tunnel, client: client)
            case .remote:
                try await startRemoteForward(tunnel, client: client)
            case .dynamic:
                try await startDynamicForward(tunnel, client: client)
            }
            
            // Update tunnel status
            if let index = tunnels.firstIndex(where: { $0.id == tunnel.id }) {
                tunnels[index].isActive = true
                activeTunnels.insert(tunnel.id)
                saveTunnels()
            }
        } catch {
            throw SSHError.commandFailed("Port forward failed: \(error.localizedDescription)")
        }
    }
    
    func stopForwarding(_ tunnel: PortForwardTunnel) async {
        // Clean up forwarded port
        forwardedPorts.removeValue(forKey: tunnel.id)
        
        // Update status
        if let index = tunnels.firstIndex(where: { $0.id == tunnel.id }) {
            tunnels[index].isActive = false
            activeTunnels.remove(tunnel.id)
            saveTunnels()
        }
    }
    
    func stopAllForwarding() async {
        for tunnel in tunnels where tunnel.isActive {
            await stopForwarding(tunnel)
        }
    }
    
    // MARK: - Private Forwarding Implementation
    
    private func startLocalForward(_ tunnel: PortForwardTunnel, client: SSHClient) async throws {
        // TODO: Implement when Citadel API is available
        // Local forwarding: localhost:localPort -> remoteHost:remotePort
        throw PortForwardError.operationFailed("Port forwarding not yet implemented")
    }
    
    private func startRemoteForward(_ tunnel: PortForwardTunnel, client: SSHClient) async throws {
        // TODO: Implement when Citadel API is available
        // Remote forwarding: remoteHost:remotePort -> localhost:localPort
        throw PortForwardError.operationFailed("Port forwarding not yet implemented")
    }
    
    private func startDynamicForward(_ tunnel: PortForwardTunnel, client: SSHClient) async throws {
        // Dynamic forwarding: SOCKS proxy on localhost:localPort
        // Implementation would set up SOCKS proxy
        // Citadel may not support this directly, would need custom implementation
        
        // Placeholder for now
        throw SSHError.commandFailed("Dynamic forwarding not yet implemented")
    }
    
    // MARK: - Persistence
    
    private func loadTunnels() {
        if let data = UserDefaults.standard.data(forKey: "port_forward_tunnels"),
           let loaded = try? JSONDecoder().decode([PortForwardTunnel].self, from: data) {
            // Reset active status on load
            tunnels = loaded.map { tunnel in
                var t = tunnel
                t.isActive = false
                return t
            }
        }
    }
    
    private func saveTunnels() {
        if let data = try? JSONEncoder().encode(tunnels) {
            UserDefaults.standard.set(data, forKey: "port_forward_tunnels")
        }
    }
    
    // MARK: - Validation
    
    func isPortAvailable(_ port: Int) -> Bool {
        // Check if port is already in use by another tunnel
        return !tunnels.contains { $0.localPort == port && $0.isActive }
    }
    
    func validateTunnel(_ tunnel: PortForwardTunnel) -> String? {
        if tunnel.name.isEmpty {
            return "Name cannot be empty"
        }
        
        if tunnel.localPort < 1 || tunnel.localPort > 65535 {
            return "Invalid local port"
        }
        
        if tunnel.remotePort < 1 || tunnel.remotePort > 65535 {
            return "Invalid remote port"
        }
        
        if !isPortAvailable(tunnel.localPort) {
            return "Port \(tunnel.localPort) is already in use"
        }
        
        return nil
    }
}
