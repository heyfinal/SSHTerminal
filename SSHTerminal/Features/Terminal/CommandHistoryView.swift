//
//  CommandHistoryView.swift
//  SSHTerminal
//
//  Phase 5: Command History Browser UI
//

import SwiftUI

struct CommandHistoryView: View {
    @StateObject private var history = CommandHistory.shared
    @State private var searchText = ""
    @State private var selectedServer: UUID? = nil
    @State private var showingExport = false
    @State private var exportText = ""
    
    var onSelectCommand: ((String) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics bar
                statisticsBar
                
                Divider()
                
                // History list
                historyList
            }
            .searchable(text: $searchText, prompt: "Search commands...")
            .navigationTitle("Command History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { exportHistory() }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: { history.clearAll() }) {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingExport) {
                ShareSheet(activityItems: [exportText])
            }
        }
    }
    
    private var statisticsBar: some View {
        HStack(spacing: 20) {
            StatBadge(label: "Total", value: "\(history.totalCommands())")
            StatBadge(label: "Today", value: "\(history.commandsToday())")
            StatBadge(label: "This Week", value: "\(history.commandsThisWeek())")
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var historyList: some View {
        List {
            if filteredEntries.isEmpty {
                Text("No command history")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(groupedEntries.keys.sorted(by: >), id: \.self) { date in
                    Section(formatSectionHeader(date)) {
                        ForEach(groupedEntries[date] ?? []) { entry in
                            CommandHistoryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let callback = onSelectCommand {
                                        callback(entry.command)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        history.deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        UIPasteboard.general.string = entry.command
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var filteredEntries: [CommandHistoryEntry] {
        if searchText.isEmpty {
            return selectedServer.map { history.historyForServer($0) } ?? history.entries
        } else {
            return history.searchHistory(query: searchText)
        }
    }
    
    private var groupedEntries: [Date: [CommandHistoryEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
    }
    
    private func formatSectionHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func exportHistory() {
        exportText = history.exportHistory(serverId: selectedServer)
        showingExport = true
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - History Row

struct CommandHistoryRow: View {
    let entry: CommandHistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatTime(entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(entry.serverName)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                if let exitCode = entry.exitCode {
                    Text(exitCode == 0 ? "✓" : "✗")
                        .font(.caption)
                        .foregroundColor(exitCode == 0 ? .green : .red)
                }
            }
            
            Text(entry.command)
                .font(.system(.body, design: .monospaced))
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Frequent Commands View

struct FrequentCommandsView: View {
    @StateObject private var history = CommandHistory.shared
    let serverId: UUID?
    
    var onSelectCommand: ((String) -> Void)?
    
    var body: some View {
        List {
            ForEach(history.frequentCommands(serverId: serverId), id: \.command) { item in
                HStack {
                    Text(item.command)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text("\(item.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectCommand?(item.command)
                }
            }
        }
        .navigationTitle("Frequent Commands")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
