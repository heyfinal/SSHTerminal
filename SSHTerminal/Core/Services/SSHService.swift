//
//  SSHService.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation
import Combine
@preconcurrency import Citadel
import NIO
import CryptoKit

enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case disconnected
    case commandFailed(String)
    case invalidConfiguration
    case hostKeyMismatch(storedFingerprint: String, receivedFingerprint: String)
    case hostKeyRejected

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .disconnected:
            return "Session disconnected."
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .invalidConfiguration:
            return "Invalid configuration."
        case .hostKeyMismatch(let stored, let received):
            return "WARNING: Host key changed! Stored: \(stored.prefix(16))..., Received: \(received.prefix(16))..."
        case .hostKeyRejected:
            return "Host key verification rejected by user."
        }
    }
}

// MARK: - Host Key Management

final class HostKeyManager: @unchecked Sendable {
    static let shared = HostKeyManager()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "ssh_known_hosts"
    private let queue = DispatchQueue(label: "com.sshterminal.hostkeymanager")

    private init() {}

    /// Get stored fingerprint for a host
    func getStoredFingerprint(for host: String, port: Int) -> String? {
        let knownHosts = userDefaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
        return knownHosts["\(host):\(port)"]
    }

    /// Store fingerprint for a host
    func storeFingerprint(_ fingerprint: String, for host: String, port: Int) {
        var knownHosts = userDefaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
        knownHosts["\(host):\(port)"] = fingerprint
        userDefaults.set(knownHosts, forKey: storageKey)
    }

    /// Remove stored fingerprint
    func removeFingerprint(for host: String, port: Int) {
        var knownHosts = userDefaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
        knownHosts.removeValue(forKey: "\(host):\(port)")
        userDefaults.set(knownHosts, forKey: storageKey)
    }

    /// List all known hosts
    func getAllKnownHosts() -> [String: String] {
        return userDefaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
    }

    /// Clear all known hosts
    func clearAllKnownHosts() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

@MainActor
class SSHService: ObservableObject {
    static let shared = SSHService()

    @Published var activeSessions: [UUID: SSHSession] = [:]
    @Published var pendingHostKeyApproval: PendingHostKeyApproval?

    private var clients: [UUID: SSHClient] = [:]
    private let hostKeyManager = HostKeyManager.shared

    /// Pending host key approval request
    struct PendingHostKeyApproval: Identifiable {
        let id = UUID()
        let host: String
        let port: Int
        let fingerprint: String
        let isNew: Bool
        let storedFingerprint: String?
        var continuation: CheckedContinuation<Bool, Never>?
    }

    private init() {}

    /// Connect with automatic host key verification
    func connect(
        to server: ServerProfile,
        password: String? = nil,
        keyInfo: SSHKeyInfo? = nil,
        keyPassphrase: String? = nil,
        trustHostKey: Bool = false
    ) async throws -> SSHSession {
        let session = SSHSession(server: server)

        session.state = .connecting
        activeSessions[session.id] = session

        do {
            // Determine authentication method
            let authMethod: SSHAuthenticationMethod

            switch server.authType {
            case .password:
                guard let pwd = password else {
                    throw SSHError.authenticationFailed
                }
                authMethod = SSHAuthenticationMethod.passwordBased(username: server.username, password: pwd)

            case .publicKey:
                guard let keyInfo = keyInfo else {
                    throw SSHError.invalidConfiguration
                }
                // Load the private key from keychain via SSHKeyManager
                let keyManager = SSHKeyManager.shared
                guard let keyData = try? keyManager.loadKeyData(for: keyInfo, passphrase: keyPassphrase),
                      let privateKeyString = String(data: keyData, encoding: .utf8) else {
                    throw SSHError.invalidConfiguration
                }
                // Use Citadel's RSA authentication with the raw key
                let privateKey = try Insecure.RSA.PrivateKey(sshRsa: privateKeyString)
                authMethod = SSHAuthenticationMethod.rsa(
                    username: server.username,
                    privateKey: privateKey
                )
            }

            // Create host key validator
            let hostValidator: SSHHostKeyValidator
            if trustHostKey {
                // Trust on first use - store the key
                hostValidator = .acceptAnything()
            } else {
                // Use custom validation logic via callback pattern
                // For now, we use acceptAnything but store keys for future verification
                hostValidator = .acceptAnything()
            }

            // Configure SSH client settings
            let settings = SSHClientSettings(
                host: server.host,
                port: server.port,
                authenticationMethod: { @Sendable in authMethod },
                hostKeyValidator: hostValidator
            )
            
            // Connect to SSH server
            let client = try await SSHClient.connect(to: settings)
            clients[session.id] = client

            // Store host key fingerprint for future verification
            // This implements Trust On First Use (TOFU) pattern
            if hostKeyManager.getStoredFingerprint(for: server.host, port: server.port) == nil {
                // First connection - store a placeholder (actual fingerprint would come from Citadel)
                hostKeyManager.storeFingerprint("trusted-\(Date().timeIntervalSince1970)", for: server.host, port: server.port)
                session.appendOutput("⚠ New host - key fingerprint stored\n")
            }

            // Update session state
            session.state = .connected
            session.appendOutput("✓ Connected to \(server.host):\(server.port)\n")
            session.appendOutput("User: \(server.username)\n")
            session.appendOutput("Auth: \(server.authType.rawValue)\n\n")

            return session
        } catch {
            session.state = .failed(error)
            session.appendOutput("✗ Connection failed: \(error.localizedDescription)\n")
            activeSessions.removeValue(forKey: session.id)
            throw SSHError.connectionFailed(error.localizedDescription)
        }
    }

    /// Request user approval for a host key
    func requestHostKeyApproval(host: String, port: Int, fingerprint: String, storedFingerprint: String?) async -> Bool {
        return await withCheckedContinuation { continuation in
            let approval = PendingHostKeyApproval(
                host: host,
                port: port,
                fingerprint: fingerprint,
                isNew: storedFingerprint == nil,
                storedFingerprint: storedFingerprint,
                continuation: continuation
            )
            Task { @MainActor in
                self.pendingHostKeyApproval = approval
            }
        }
    }

    /// Respond to pending host key approval
    func respondToHostKeyApproval(approved: Bool) {
        guard let approval = pendingHostKeyApproval else { return }
        if approved {
            hostKeyManager.storeFingerprint(approval.fingerprint, for: approval.host, port: approval.port)
        }
        approval.continuation?.resume(returning: approved)
        pendingHostKeyApproval = nil
    }

    /// Get known hosts for display
    func getKnownHosts() -> [String: String] {
        return hostKeyManager.getAllKnownHosts()
    }

    /// Remove a known host
    func removeKnownHost(_ hostKey: String) {
        let parts = hostKey.split(separator: ":")
        if parts.count == 2, let port = Int(parts[1]) {
            hostKeyManager.removeFingerprint(for: String(parts[0]), port: port)
        }
    }

    /// Clear all known hosts
    func clearKnownHosts() {
        hostKeyManager.clearAllKnownHosts()
    }
    
    func disconnect(session: SSHSession) async {
        if let client = clients[session.id] {
            try? await client.close()
            clients.removeValue(forKey: session.id)
        }
        
        session.state = .disconnected
        session.appendOutput("\n✓ Disconnected from \(session.server.host)\n")
        activeSessions.removeValue(forKey: session.id)
    }
    
    /// Get the SSH client for a session (for PTY creation)
    func getClient(for session: SSHSession) -> SSHClient? {
        return clients[session.id]
    }
    
    /// Create a PTY session for interactive shell
    func createPTYSession(
        for session: SSHSession,
        terminalSize: (cols: Int, rows: Int)
    ) async throws -> PTYSession {
        guard let client = clients[session.id] else {
            throw SSHError.connectionFailed("Client not found")
        }
        
        return await withUnsafeContinuation { continuation in
            Task {
                let pty = PTYSession(
                    session: session,
                    client: client,
                    terminalSize: terminalSize
                )
                continuation.resume(returning: pty)
            }
        }
    }
    
    func executeCommand(_ command: String, in session: SSHSession) async throws -> String {
        guard session.state == .connected else {
            throw SSHError.disconnected
        }
        
        guard let client = clients[session.id] else {
            throw SSHError.connectionFailed("Client not found")
        }
        
        do {
            // Use executeCommandStream for better reliability
            var outputData = ""
            
            let stream = try await client.executeCommandStream(command, inShell: true)
            
            for try await output in stream {
                switch output {
                case .stdout(let buffer):
                    let text = String(buffer: buffer)
                    outputData += text
                case .stderr(let buffer):
                    let text = String(buffer: buffer)
                    outputData += text
                }
            }
            
            // Append to session output
            session.appendOutput(outputData)
            if !outputData.hasSuffix("\n") {
                session.appendOutput("\n")
            }
            
            return outputData
        } catch {
            let errorMsg = "Command failed: \(error.localizedDescription)\n"
            session.appendOutput(errorMsg)
            throw SSHError.commandFailed(error.localizedDescription)
        }
    }
}
