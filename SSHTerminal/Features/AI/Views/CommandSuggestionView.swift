import SwiftUI

struct CommandSuggestionView: View {
    @StateObject private var aiService = AIService.shared
    @State private var suggestions: [CommandSuggestion] = []
    @State private var isLoading: Bool = false
    
    let context: CommandContext
    let onSelectCommand: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Getting suggestions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
            } else if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Suggested Commands")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { suggestions.removeAll() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(suggestions) { suggestion in
                                SuggestionCard(suggestion: suggestion, onSelect: {
                                    onSelectCommand(suggestion.command)
                                    suggestions.removeAll()
                                })
                            }
                        }
                        .padding()
                    }
                    .background(Color(.secondarySystemBackground))
                }
            }
        }
        .onAppear {
            loadSuggestions()
        }
    }
    
    func loadSuggestions() {
        guard aiService.isEnabled else { return }
        
        isLoading = true
        Task {
            do {
                let newSuggestions = try await aiService.suggestCommands(context: context)
                await MainActor.run {
                    suggestions = newSuggestions
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    func refresh() {
        suggestions.removeAll()
        loadSuggestions()
    }
}

struct SuggestionCard: View {
    let suggestion: CommandSuggestion
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(suggestion.command)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: 200, alignment: .leading)
            }
            .padding(12)
            .frame(width: 220)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
