//
// SecurityFixes.swift
// SSHTerminal
//
// Critical security fixes for host key verification
//

import Foundation
import Citadel
import NIO

/// Secure host key validator that implements proper TOFU (Trust On First Use)
actor SecureHostKeyValidator {
    private let hostKeyManager = HostKeyManager.shared
    private let host: String
    private let port: Int
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    /// Create a proper host key validator
    func createValidator(trustOnFirstUse: Bool) async -> SSHHostKeyValidator {
        // Get stored fingerprint
        let storedFingerprint = hostKeyManager.getStoredFingerprint(for: host, port: port)
        
        return SSHHostKeyValidator { proposedKey in
            // Calculate fingerprint of proposed key
            let fingerprint = self.calculateFingerprint(proposedKey)
            
            if let stored = storedFingerprint {
                // We have a stored key - verify it matches
                if fingerprint == stored {
                    return true // Key matches
                } else {
                    // KEY MISMATCH - Potential MITM attack!
                    print("⚠️  WARNING: Host key mismatch for \(self.host):\(self.port)")
                    print("   Stored:   \(stored)")
                    print("   Proposed: \(fingerprint)")
                    return false // REJECT mismatched keys
                }
            } else {
                // First time seeing this host
                if trustOnFirstUse {
                    // Store the key for future verification
                    self.hostKeyManager.storeFingerprint(fingerprint, for: self.host, port: self.port)
                    print("✅ Stored host key for \(self.host):\(self.port)")
                    return true
                } else {
                    // Require user approval
                    print("❌ Unknown host key for \(self.host):\(self.port) - user approval required")
                    return false
                }
            }
        }
    }
    
    /// Calculate SHA256 fingerprint of host key
    private func calculateFingerprint(_ key: NIOSSHPublicKey) -> String {
        // Convert key to data and hash it
        let keyData = key.rawRepresentation
        let hash = SHA256.hash(data: keyData)
        return hash.compactMap { String(format: "%02x", $0) }.joined(separator: ":")
    }
}

// Polyfill for SHA256 if not available
import CryptoKit
extension SHA256 {
    static func hash(data: Data) -> SHA256Digest {
        return CryptoKit.SHA256.hash(data: data)
    }
}
