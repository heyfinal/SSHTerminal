//
// SecurityFixes.swift
// SSHTerminal
//
// Critical security fixes for host key verification
//

import Foundation
import CryptoKit
@preconcurrency import Citadel
import NIO

/// Secure host key validator that implements proper TOFU (Trust On First Use)
/// This is a non-actor class because the SSHHostKeyValidator closure is synchronous
final class SecureHostKeyValidator: @unchecked Sendable {
    private let hostKeyManager = HostKeyManager.shared
    private let host: String
    private let port: Int

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    /// Create a proper host key validator
    func createValidator(trustOnFirstUse: Bool) -> SSHHostKeyValidator {
        // Capture values for use in closure (avoid capturing self)
        let storedFingerprint = hostKeyManager.getStoredFingerprint(for: host, port: port)
        let hostKeyMgr = hostKeyManager
        let hostName = host
        let portNum = port

        return SSHHostKeyValidator { proposedKey in
            // Calculate fingerprint of proposed key
            let fingerprint = Self.calculateFingerprint(proposedKey)

            if let stored = storedFingerprint {
                // We have a stored key - verify it matches
                if fingerprint == stored {
                    return true // Key matches
                } else {
                    // KEY MISMATCH - Potential MITM attack!
                    print("⚠️  WARNING: Host key mismatch for \(hostName):\(portNum)")
                    print("   Stored:   \(stored)")
                    print("   Proposed: \(fingerprint)")
                    return false // REJECT mismatched keys
                }
            } else {
                // First time seeing this host
                if trustOnFirstUse {
                    // Store the key for future verification
                    hostKeyMgr.storeFingerprint(fingerprint, for: hostName, port: portNum)
                    print("✅ Stored host key for \(hostName):\(portNum)")
                    return true
                } else {
                    // Require user approval
                    print("❌ Unknown host key for \(hostName):\(portNum) - user approval required")
                    return false
                }
            }
        }
    }

    /// Calculate SHA256 fingerprint of host key
    private static func calculateFingerprint(_ key: NIOSSHPublicKey) -> String {
        // Convert key to data and hash it
        let keyData = key.rawRepresentation
        let hash = CryptoKit.SHA256.hash(data: keyData)
        return hash.compactMap { String(format: "%02x", $0) }.joined(separator: ":")
    }
}
