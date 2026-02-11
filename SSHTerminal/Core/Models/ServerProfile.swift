//
//  ServerProfile.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation

enum AuthType: String, Codable, CaseIterable {
    case password
    case publicKey
}

struct ServerProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var port: Int
    var username: String
    var authType: AuthType
    var privateKeyPath: String?
    var createdAt: Date
    var lastConnectedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authType: AuthType = .password,
        privateKeyPath: String? = nil,
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authType = authType
        self.privateKeyPath = privateKeyPath
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
    }
    
    var displayAddress: String {
        "\(username)@\(host):\(port)"
    }
}
