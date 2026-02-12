//
//  ServerListViewModel.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation
import Combine

@MainActor
class ServerListViewModel: ObservableObject {
    @Published var servers: [ServerProfile] = []
    @Published var isShowingAddSheet = false
    @Published var isShowingEditSheet = false
    @Published var serverToEdit: ServerProfile?
    @Published var selectedServer: ServerProfile?
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    private let repository = ServerRepository.shared
    private let sshService = SSHService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        repository.$servers
            .assign(to: &$servers)
    }
    
    func addServer(_ server: ServerProfile) {
        repository.addServer(server)
    }
    
    func updateServer(_ server: ServerProfile) {
        repository.updateServer(server)
    }
    
    func deleteServer(_ server: ServerProfile) {
        repository.deleteServer(server)
    }
    
    func connectToServer(_ server: ServerProfile, password: String?) async {
        isConnecting = true
        errorMessage = nil
        
        do {
            let session = try await sshService.connect(to: server, password: password)
            selectedServer = server
            
            // Update last connected time
            var updatedServer = server
            updatedServer.lastConnectedAt = Date()
            repository.updateServer(updatedServer)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isConnecting = false
    }
}
