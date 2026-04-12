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
    @Published var isShowingScanSheet = false

    private let repository = ServerRepository.shared
    private let sshService = SSHService.shared
    private let keychain = KeychainService.shared
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
        // Clean up saved password from keychain if present
        if server.savedPassword {
            try? keychain.delete(for: server.passwordKeychainKey)
        }
        repository.deleteServer(server)
    }

    // MARK: - Credential Management

    func savedPassword(for server: ServerProfile) -> String? {
        guard server.savedPassword, server.authType == .password else { return nil }
        return try? keychain.retrieve(for: server.passwordKeychainKey)
    }

    func savePassword(_ password: String, for server: ServerProfile) {
        try? keychain.save(password: password, for: server.passwordKeychainKey)
        var updated = server
        updated.savedPassword = true
        repository.updateServer(updated)
    }

    func deletePassword(for server: ServerProfile) {
        try? keychain.delete(for: server.passwordKeychainKey)
        var updated = server
        updated.savedPassword = false
        repository.updateServer(updated)
    }

    // MARK: - Connection

    /// Connect using saved credentials if available, otherwise use provided password
    func connectToServer(_ server: ServerProfile, password: String? = nil) async {
        isConnecting = true
        errorMessage = nil

        let resolvedPassword: String?
        if let saved = savedPassword(for: server) {
            resolvedPassword = saved
        } else {
            resolvedPassword = password
        }

        do {
            let session = try await sshService.connect(to: server, password: resolvedPassword)
            selectedServer = server

            var updatedServer = server
            updatedServer.lastConnectedAt = Date()
            repository.updateServer(updatedServer)
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }

    func needsPasswordPrompt(for server: ServerProfile) -> Bool {
        guard server.authType == .password else { return false }
        return savedPassword(for: server) == nil
    }
}
