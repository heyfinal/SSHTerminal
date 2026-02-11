//
//  SnippetRepository.swift
//  SSHTerminal
//
//  Phase 5: Snippet Storage and Management
//

import Foundation
import Combine

@MainActor
class SnippetRepository: ObservableObject {
    static let shared = SnippetRepository()
    
    @Published var snippets: [Snippet] = []
    @Published var categories: [String] = []
    
    private let storageKey = "ssh_snippets"
    private let categoriesKey = "snippet_categories"
    
    private init() {
        loadSnippets()
        loadCategories()
        
        // Initialize with defaults if empty
        if snippets.isEmpty {
            initializeDefaults()
        }
    }
    
    // MARK: - Snippet Operations
    
    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
        updateCategories()
        saveSnippets()
    }
    
    func updateSnippet(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
            updateCategories()
            saveSnippets()
        }
    }
    
    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        updateCategories()
        saveSnippets()
    }
    
    func toggleFavorite(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index].isFavorite.toggle()
            saveSnippets()
        }
    }
    
    func recordUsage(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index].usageCount += 1
            snippets[index].lastUsedAt = Date()
            saveSnippets()
        }
    }
    
    // MARK: - Search and Filter
    
    func searchSnippets(query: String) -> [Snippet] {
        guard !query.isEmpty else { return snippets }
        
        let lowercased = query.lowercased()
        return snippets.filter { snippet in
            snippet.name.lowercased().contains(lowercased) ||
            snippet.command.lowercased().contains(lowercased) ||
            snippet.description.lowercased().contains(lowercased) ||
            snippet.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    func snippets(inCategory category: String) -> [Snippet] {
        snippets.filter { $0.category == category }
    }
    
    func favoriteSnippets() -> [Snippet] {
        snippets.filter { $0.isFavorite }
    }
    
    func recentlyUsedSnippets(limit: Int = 10) -> [Snippet] {
        snippets
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    func mostUsedSnippets(limit: Int = 10) -> [Snippet] {
        snippets
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Categories
    
    func addCategory(_ name: String) {
        if !categories.contains(name) {
            categories.append(name)
            categories.sort()
            saveCategories()
        }
    }
    
    func deleteCategory(_ name: String) {
        // Move snippets in this category to "General"
        for i in 0..<snippets.count {
            if snippets[i].category == name {
                snippets[i].category = "General"
            }
        }
        
        categories.removeAll { $0 == name }
        saveSnippets()
        saveCategories()
    }
    
    func renameCategory(from oldName: String, to newName: String) {
        // Update all snippets in this category
        for i in 0..<snippets.count {
            if snippets[i].category == oldName {
                snippets[i].category = newName
            }
        }
        
        if let index = categories.firstIndex(of: oldName) {
            categories[index] = newName
            categories.sort()
        }
        
        saveSnippets()
        saveCategories()
    }
    
    private func updateCategories() {
        let snippetCategories = Set(snippets.map { $0.category })
        let allCategories = categories + snippetCategories.filter { !categories.contains($0) }
        categories = Array(Set(allCategories)).sorted()
        saveCategories()
    }
    
    // MARK: - Import/Export
    
    func exportSnippets() -> Data? {
        try? JSONEncoder().encode(snippets)
    }
    
    func importSnippets(from data: Data, merge: Bool = false) throws {
        let imported = try JSONDecoder().decode([Snippet].self, from: data)
        
        if merge {
            // Merge: Add new snippets, skip duplicates
            let existingIds = Set(snippets.map { $0.id })
            let newSnippets = imported.filter { !existingIds.contains($0.id) }
            snippets.append(contentsOf: newSnippets)
        } else {
            // Replace all
            snippets = imported
        }
        
        updateCategories()
        saveSnippets()
    }
    
    // MARK: - Persistence
    
    private func loadSnippets() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = loaded
        }
    }
    
    private func saveSnippets() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadCategories() {
        if let saved = UserDefaults.standard.array(forKey: categoriesKey) as? [String] {
            categories = saved
        } else {
            categories = ["General", "System", "Network", "Files", "Git", "Docker", "Processes", "Logs"]
        }
    }
    
    private func saveCategories() {
        UserDefaults.standard.set(categories, forKey: categoriesKey)
    }
    
    private func initializeDefaults() {
        snippets = Snippet.defaultSnippets
        saveSnippets()
    }
    
    // MARK: - iCloud Sync Support (Placeholder)
    
    func enableiCloudSync() {
        // TODO: Implement iCloud sync using NSUbiquitousKeyValueStore or CloudKit
    }
    
    func syncWithiCloud() {
        // TODO: Implement sync logic
    }
}
