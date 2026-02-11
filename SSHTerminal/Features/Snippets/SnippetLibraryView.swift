//
//  SnippetLibraryView.swift
//  SSHTerminal
//
//  Phase 5: Snippet Library UI
//

import SwiftUI

struct SnippetLibraryView: View {
    @StateObject private var repository = SnippetRepository.shared
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingAddSnippet = false
    @State private var editingSnippet: Snippet?
    @State private var showingCategoryManager = false
    
    var onSelectSnippet: ((Snippet) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                categoryPicker
                
                Divider()
                
                // Snippet list
                snippetList
            }
            .searchable(text: $searchText, prompt: "Search snippets...")
            .navigationTitle("Snippets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingCategoryManager = true
                    } label: {
                        Image(systemName: "folder")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSnippet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSnippet) {
                SnippetEditorView(repository: repository)
            }
            .sheet(item: $editingSnippet) { snippet in
                SnippetEditorView(repository: repository, editingSnippet: snippet)
            }
            .sheet(isPresented: $showingCategoryManager) {
                CategoryManagerView(repository: repository)
            }
        }
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(name: "All", isSelected: selectedCategory == "All") {
                    selectedCategory = "All"
                }
                
                CategoryChip(name: "Favorites", isSelected: selectedCategory == "Favorites") {
                    selectedCategory = "Favorites"
                }
                
                CategoryChip(name: "Recent", isSelected: selectedCategory == "Recent") {
                    selectedCategory = "Recent"
                }
                
                ForEach(repository.categories, id: \.self) { category in
                    CategoryChip(name: category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
    
    private var snippetList: some View {
        List {
            ForEach(filteredSnippets) { snippet in
                SnippetRowView(snippet: snippet, repository: repository)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let callback = onSelectSnippet {
                            repository.recordUsage(snippet)
                            callback(snippet)
                        } else {
                            editingSnippet = snippet
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            repository.deleteSnippet(snippet)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            editingSnippet = snippet
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            repository.toggleFavorite(snippet)
                        } label: {
                            Label("Favorite", systemImage: snippet.isFavorite ? "star.fill" : "star")
                        }
                        .tint(.yellow)
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private var filteredSnippets: [Snippet] {
        var snippets: [Snippet]
        
        switch selectedCategory {
        case "All":
            snippets = repository.snippets
        case "Favorites":
            snippets = repository.favoriteSnippets()
        case "Recent":
            snippets = repository.recentlyUsedSnippets()
        default:
            snippets = repository.snippets(inCategory: selectedCategory)
        }
        
        if !searchText.isEmpty {
            snippets = repository.searchSnippets(query: searchText)
        }
        
        return snippets
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

// MARK: - Snippet Row

struct SnippetRowView: View {
    let snippet: Snippet
    @ObservedObject var repository: SnippetRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snippet.name)
                    .font(.headline)
                
                Spacer()
                
                if snippet.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                if snippet.usageCount > 0 {
                    Text("\(snippet.usageCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            
            Text(snippet.command)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
                .lineLimit(2)
            
            if !snippet.description.isEmpty {
                Text(snippet.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(snippet.category, systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !snippet.tags.isEmpty {
                    ForEach(snippet.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Snippet Editor

struct SnippetEditorView: View {
    @ObservedObject var repository: SnippetRepository
    var editingSnippet: Snippet?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var command: String
    @State private var category: String
    @State private var description: String
    @State private var tags: String
    @State private var showingVariableHelper = false
    
    init(repository: SnippetRepository, editingSnippet: Snippet? = nil) {
        self.repository = repository
        self.editingSnippet = editingSnippet
        
        _name = State(initialValue: editingSnippet?.name ?? "")
        _command = State(initialValue: editingSnippet?.command ?? "")
        _category = State(initialValue: editingSnippet?.category ?? "General")
        _description = State(initialValue: editingSnippet?.description ?? "")
        _tags = State(initialValue: editingSnippet?.tags.joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(repository.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section {
                    TextEditor(text: $command)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                    
                    Button {
                        showingVariableHelper = true
                    } label: {
                        Label("Insert Variable", systemImage: "curlybraces")
                    }
                } header: {
                    Text("Command")
                } footer: {
                    Text("Use {variable} for placeholders. Built-in: {date}, {time}, {datetime}")
                        .font(.caption)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                }
                
                Section("Tags") {
                    TextField("Tags (comma separated)", text: $tags)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle(editingSnippet == nil ? "New Snippet" : "Edit Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSnippet()
                    }
                    .disabled(name.isEmpty || command.isEmpty)
                }
            }
            .sheet(isPresented: $showingVariableHelper) {
                VariableHelperView(command: $command)
            }
        }
    }
    
    private func saveSnippet() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let snippet = Snippet(
            id: editingSnippet?.id ?? UUID(),
            name: name,
            command: command,
            category: category,
            tags: tagArray,
            description: description,
            isFavorite: editingSnippet?.isFavorite ?? false,
            usageCount: editingSnippet?.usageCount ?? 0,
            lastUsedAt: editingSnippet?.lastUsedAt
        )
        
        if editingSnippet != nil {
            repository.updateSnippet(snippet)
        } else {
            repository.addSnippet(snippet)
        }
        
        dismiss()
    }
}

// MARK: - Variable Helper

struct VariableHelperView: View {
    @Binding var command: String
    @Environment(\.dismiss) private var dismiss
    
    let commonVariables = [
        ("{date}", "Current date (YYYY-MM-DD)"),
        ("{time}", "Current time (HH:MM:SS)"),
        ("{datetime}", "Current date and time"),
        ("{user}", "Username"),
        ("{host}", "Hostname"),
        ("{path}", "File path"),
        ("{name}", "Name/identifier"),
        ("{port}", "Port number"),
        ("{service}", "Service name"),
        ("{logfile}", "Log file path"),
        ("{directory}", "Directory path")
    ]
    
    var body: some View {
        NavigationView {
            List(commonVariables, id: \.0) { variable, description in
                Button {
                    command += variable
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(variable)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Insert Variable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Category Manager

struct CategoryManagerView: View {
    @ObservedObject var repository: SnippetRepository
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(repository.categories, id: \.self) { category in
                    HStack {
                        Text(category)
                        
                        Spacer()
                        
                        Text("\(repository.snippets(inCategory: category).count)")
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        repository.deleteCategory(repository.categories[index])
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                NavigationView {
                    Form {
                        TextField("Category Name", text: $newCategoryName)
                            .autocapitalization(.words)
                    }
                    .navigationTitle("New Category")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddCategory = false
                                newCategoryName = ""
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                repository.addCategory(newCategoryName)
                                showingAddCategory = false
                                newCategoryName = ""
                            }
                            .disabled(newCategoryName.isEmpty)
                        }
                    }
                }
            }
        }
    }
}
