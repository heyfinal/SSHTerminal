//
//  KeychainService.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Keychain item not found"
        case .duplicateItem:
            return "Keychain item already exists"
        case .unexpectedStatus(let status):
            return "Keychain error: \(status)"
        case .encodingFailed:
            return "Failed to encode password data"
        }
    }
}

final class KeychainService: @unchecked Sendable {
    static let shared = KeychainService()

    private let service: String

    private init() {
        // Use bundle identifier if available, fall back to default
        self.service = Bundle.main.bundleIdentifier ?? "com.daniel.sshterminal"
    }

    func save(password: String, for account: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(password: password, for: account)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func retrieve(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? KeychainError.itemNotFound : KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.itemNotFound
        }
        
        return password
    }
    
    func delete(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func update(password: String, for account: String) throws {
        guard let data = password.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Check if a key exists without retrieving its value
    func exists(for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// List all stored accounts
    func listAccounts() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}
