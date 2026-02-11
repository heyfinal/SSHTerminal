//
//  SSHKeyManager.swift
//  SSHTerminal
//
//  Phase 5: SSH Key Authentication Manager
//

import Foundation
import Security
import CryptoKit

enum SSHKeyError: Error {
    case keyNotFound
    case invalidKeyFormat
    case passphraseRequired
    case invalidPassphrase
    case keychainError(OSStatus)
    case fileAccessError
}

enum SSHKeyType: String, Codable {
    case rsa
    case ecdsa
    case ed25519
    
    var displayName: String {
        switch self {
        case .rsa: return "RSA"
        case .ecdsa: return "ECDSA"
        case .ed25519: return "Ed25519"
        }
    }
}

struct SSHKeyInfo: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: SSHKeyType
    var fingerprint: String
    var createdAt: Date
    var isEncrypted: Bool

    /// Path to retrieve the private key (computed from keychain identifier)
    var privateKeyPath: String {
        "keychain://\(id.uuidString)"
    }

    init(id: UUID = UUID(), name: String, type: SSHKeyType, fingerprint: String, isEncrypted: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.fingerprint = fingerprint
        self.createdAt = Date()
        self.isEncrypted = isEncrypted
    }
}

@MainActor
class SSHKeyManager: ObservableObject {
    static let shared = SSHKeyManager()
    
    @Published var availableKeys: [SSHKeyInfo] = []
    
    private let keychainService = KeychainService.shared
    private let keysDirectoryKey = "ssh_keys_directory"
    
    private init() {
        loadKeys()
    }
    
    // MARK: - Key Management
    
    func importKey(name: String, pemData: Data, passphrase: String? = nil) throws -> SSHKeyInfo {
        // Detect key type
        let pemString = String(data: pemData, encoding: .utf8) ?? ""
        let keyType = detectKeyType(from: pemString)
        
        // Check if encrypted
        let isEncrypted = pemString.contains("ENCRYPTED")
        
        // Generate fingerprint
        let fingerprint = generateFingerprint(from: pemData)
        
        // Store key in keychain
        let keyInfo = SSHKeyInfo(
            name: name,
            type: keyType,
            fingerprint: fingerprint,
            isEncrypted: isEncrypted
        )
        
        // Save private key data
        try keychainService.saveSSHKey(keyInfo.id.uuidString, data: pemData)
        
        // Save passphrase if provided
        if let passphrase = passphrase, !passphrase.isEmpty {
            try keychainService.saveSSHKeyPassphrase(keyInfo.id.uuidString, passphrase: passphrase)
        }
        
        // Update keys list
        availableKeys.append(keyInfo)
        saveKeysMetadata()
        
        return keyInfo
    }
    
    func loadKeyData(for keyInfo: SSHKeyInfo, passphrase: String? = nil) throws -> Data {
        guard let keyData = try? keychainService.retrieveSSHKey(keyInfo.id.uuidString) else {
            throw SSHKeyError.keyNotFound
        }
        
        // If key is encrypted, verify passphrase
        if keyInfo.isEncrypted {
            let storedPassphrase = try? keychainService.retrieveSSHKeyPassphrase(keyInfo.id.uuidString)
            
            if let provided = passphrase {
                // Use provided passphrase
                if let stored = storedPassphrase, stored != provided {
                    throw SSHKeyError.invalidPassphrase
                }
            } else if storedPassphrase == nil {
                throw SSHKeyError.passphraseRequired
            }
        }
        
        return keyData
    }
    
    func deleteKey(_ keyInfo: SSHKeyInfo) throws {
        // Remove from keychain
        try keychainService.deleteSSHKey(keyInfo.id.uuidString)
        try? keychainService.deleteSSHKeyPassphrase(keyInfo.id.uuidString)
        
        // Remove from list
        availableKeys.removeAll { $0.id == keyInfo.id }
        saveKeysMetadata()
    }
    
    func renameKey(_ keyInfo: SSHKeyInfo, newName: String) {
        if let index = availableKeys.firstIndex(where: { $0.id == keyInfo.id }) {
            availableKeys[index].name = newName
            saveKeysMetadata()
        }
    }
    
    // MARK: - Private Helpers
    
    private func detectKeyType(from pemString: String) -> SSHKeyType {
        if pemString.contains("BEGIN RSA") || pemString.contains("ssh-rsa") {
            return .rsa
        } else if pemString.contains("BEGIN EC") || pemString.contains("ecdsa-") {
            return .ecdsa
        } else if pemString.contains("BEGIN OPENSSH") || pemString.contains("ssh-ed25519") {
            return .ed25519
        }
        return .rsa // default
    }
    
    private func generateFingerprint(from keyData: Data) -> String {
        let hash = SHA256.hash(data: keyData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func loadKeys() {
        if let data = UserDefaults.standard.data(forKey: "ssh_keys_metadata"),
           let keys = try? JSONDecoder().decode([SSHKeyInfo].self, from: data) {
            availableKeys = keys
        }
    }
    
    private func saveKeysMetadata() {
        if let data = try? JSONEncoder().encode(availableKeys) {
            UserDefaults.standard.set(data, forKey: "ssh_keys_metadata")
        }
    }
}

// MARK: - KeychainService Extension

extension KeychainService {
    func saveSSHKey(_ identifier: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SSHTerminal.SSHKeys",
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete existing first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SSHKeyError.keychainError(status)
        }
    }
    
    func retrieveSSHKey(_ identifier: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SSHTerminal.SSHKeys",
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw SSHKeyError.keychainError(status)
        }
        
        return data
    }
    
    func deleteSSHKey(_ identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SSHTerminal.SSHKeys",
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SSHKeyError.keychainError(status)
        }
    }
    
    func saveSSHKeyPassphrase(_ identifier: String, passphrase: String) throws {
        guard let data = passphrase.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SSHTerminal.SSHKeyPassphrases",
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SSHKeyError.keychainError(status)
        }
    }
    
    func retrieveSSHKeyPassphrase(_ identifier: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SSHTerminal.SSHKeyPassphrases",
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let passphrase = String(data: data, encoding: .utf8) else {
            throw SSHKeyError.keychainError(status)
        }
        
        return passphrase
    }
    
    func deleteSSHKeyPassphrase(_ identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SSHTerminal.SSHKeyPassphrases",
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SSHKeyError.keychainError(status)
        }
    }
}
