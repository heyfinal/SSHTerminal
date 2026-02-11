//
//  CommandHistory.swift
//  SSHTerminal
//
//  Phase 5: Persistent Command History
//

import Foundation

struct CommandHistoryEntry: Identifiable, Codable {
    let id: UUID
    let command: String
    let serverId: UUID
    let serverName: String
    let timestamp: Date
    let exitCode: Int?
    
    init(
        id: UUID = UUID(),
        command: String,
        serverId: UUID,
        serverName: String,
        timestamp: Date = Date(),
        exitCode: Int? = nil
    ) {
        self.id = id
        self.command = command
        self.serverId = serverId
        self.serverName = serverName
        self.timestamp = timestamp
        self.exitCode = exitCode
    }
}

@MainActor
class CommandHistory: ObservableObject {
    static let shared = CommandHistory()
    
    @Published var entries: [CommandHistoryEntry] = []
    
    private let storageKey = "command_history"
    private let maxEntries = 1000
    
    private init() {
        loadHistory()
    }
    
    // MARK: - History Management
    
    func addCommand(_ command: String, serverId: UUID, serverName: String, exitCode: Int? = nil) {
        let entry = CommandHistoryEntry(
            command: command,
            serverId: serverId,
            serverName: serverName,
            exitCode: exitCode
        )
        
        entries.insert(entry, at: 0)
        
        // Trim to max entries
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        
        saveHistory()
    }
    
    func deleteEntry(_ entry: CommandHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveHistory()
    }
    
    func clearAll() {
        entries.removeAll()
        saveHistory()
    }
    
    func clearForServer(_ serverId: UUID) {
        entries.removeAll { $0.serverId == serverId }
        saveHistory()
    }
    
    // MARK: - Query and Search
    
    func historyForServer(_ serverId: UUID) -> [CommandHistoryEntry] {
        entries.filter { $0.serverId == serverId }
    }
    
    func searchHistory(query: String) -> [CommandHistoryEntry] {
        guard !query.isEmpty else { return entries }
        
        let lowercased = query.lowercased()
        return entries.filter { entry in
            entry.command.lowercased().contains(lowercased) ||
            entry.serverName.lowercased().contains(lowercased)
        }
    }
    
    func uniqueCommands(for serverId: UUID? = nil) -> [String] {
        let filtered = serverId.map { historyForServer($0) } ?? entries
        var seen = Set<String>()
        var unique: [String] = []
        
        for entry in filtered {
            if !seen.contains(entry.command) {
                seen.insert(entry.command)
                unique.append(entry.command)
            }
        }
        
        return unique
    }
    
    func recentCommands(limit: Int = 20, serverId: UUID? = nil) -> [CommandHistoryEntry] {
        let filtered = serverId.map { historyForServer($0) } ?? entries
        return Array(filtered.prefix(limit))
    }
    
    func frequentCommands(limit: Int = 10, serverId: UUID? = nil) -> [(command: String, count: Int)] {
        let filtered = serverId.map { historyForServer($0) } ?? entries
        
        var counts: [String: Int] = [:]
        for entry in filtered {
            counts[entry.command, default: 0] += 1
        }
        
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (command: $0.key, count: $0.value) }
    }
    
    // MARK: - Statistics
    
    func totalCommands(for serverId: UUID? = nil) -> Int {
        serverId.map { historyForServer($0).count } ?? entries.count
    }
    
    func commandsToday(for serverId: UUID? = nil) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let filtered = serverId.map { historyForServer($0) } ?? entries
        return filtered.filter { calendar.startOfDay(for: $0.timestamp) == today }.count
    }
    
    func commandsThisWeek(for serverId: UUID? = nil) -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let filtered = serverId.map { historyForServer($0) } ?? entries
        return filtered.filter { $0.timestamp >= weekAgo }.count
    }
    
    // MARK: - Export
    
    func exportHistory(serverId: UUID? = nil) -> String {
        let filtered = serverId.map { historyForServer($0) } ?? entries
        
        var output = "# SSH Terminal Command History\n"
        output += "# Exported: \(Date())\n\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        for entry in filtered.reversed() {
            output += "# \(formatter.string(from: entry.timestamp)) - \(entry.serverName)\n"
            output += "\(entry.command)\n\n"
        }
        
        return output
    }
    
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(entries)
    }
    
    // MARK: - Persistence
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([CommandHistoryEntry].self, from: data) {
            entries = loaded
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
