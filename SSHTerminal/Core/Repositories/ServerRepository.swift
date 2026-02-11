//
//  ServerRepository.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation
import Combine

@MainActor
class ServerRepository: ObservableObject {
    static let shared = ServerRepository()
    
    @Published var servers: [ServerProfile] = []
    
    private let userDefaults = UserDefaults.standard
    private let serversKey = "saved_servers"
    
    private init() {
        loadServers()
    }
    
    func loadServers() {
        guard let data = userDefaults.data(forKey: serversKey),
              let decoded = try? JSONDecoder().decode([ServerProfile].self, from: data) else {
            servers = []
            return
        }
        servers = decoded
    }
    
    func saveServers() {
        guard let encoded = try? JSONEncoder().encode(servers) else { return }
        userDefaults.set(encoded, forKey: serversKey)
    }
    
    func addServer(_ server: ServerProfile) {
        servers.append(server)
        saveServers()
    }
    
    func updateServer(_ server: ServerProfile) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }
    
    func deleteServer(_ server: ServerProfile) {
        servers.removeAll { $0.id == server.id }
        saveServers()
        
        // Clean up keychain
        try? KeychainService.shared.delete(for: server.id.uuidString)
    }
    
    func getServer(by id: UUID) -> ServerProfile? {
        servers.first { $0.id == id }
    }
}
