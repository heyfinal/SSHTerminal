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
import NIOSSH

private struct HostKeyMismatch: Error {}

/// Secure host key validator that implements proper TOFU (Trust On First Use)
final class SecureHostKeyValidator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
    private let hostKeyManager = HostKeyManager.shared
    private let host: String
    private let port: Int
    private let trustOnFirstUse: Bool

    init(host: String, port: Int, trustOnFirstUse: Bool = true) {
        self.host = host
        self.port = port
        self.trustOnFirstUse = trustOnFirstUse
    }

    /// Create a proper SSHHostKeyValidator using this delegate
    func createValidator() -> SSHHostKeyValidator {
        return .custom(self)
    }

    public func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        let fingerprint = Self.calculateFingerprint(hostKey)
        let storedFingerprint = hostKeyManager.getStoredFingerprint(for: host, port: port)

        if let stored = storedFingerprint {
            if fingerprint == stored {
                validationCompletePromise.succeed(())
            } else {
                print("⚠️  WARNING: Host key mismatch for \(host):\(port)")
                print("   Stored:   \(stored)")
                print("   Proposed: \(fingerprint)")
                validationCompletePromise.fail(HostKeyMismatch())
            }
        } else {
            if trustOnFirstUse {
                hostKeyManager.storeFingerprint(fingerprint, for: host, port: port)
                print("✅ Stored host key for \(host):\(port)")
                validationCompletePromise.succeed(())
            } else {
                print("❌ Unknown host key for \(host):\(port) - user approval required")
                validationCompletePromise.fail(HostKeyMismatch())
            }
        }
    }

    /// Calculate SHA256 fingerprint of host key
    private static func calculateFingerprint(_ key: NIOSSHPublicKey) -> String {
        var serializer = ByteBufferAllocator().buffer(capacity: 256)
        key.write(to: &serializer)
        let keyData = Data(buffer: serializer)
        let hash = CryptoKit.SHA256.hash(data: keyData)
        return hash.compactMap { String(format: "%02x", $0) }.joined(separator: ":")
    }
}
