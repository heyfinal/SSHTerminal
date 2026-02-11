import SwiftUI

struct ErrorExplanationView: View {
    let error: String
    let command: String
    let context: CommandContext
    let onSelectFix: (String) -> Void
    
    @State private var explanation: ErrorExplanation?
    @State private var isLoading: Bool = true
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Error Detected")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Analyzing error...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let explanation = explanation {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Command that failed
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Command")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(command)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        // Error message
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Error")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(error)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.red)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        // Explanation
                        VStack(alignment: .leading, spacing: 8) {
                            Label("What Went Wrong", systemImage: "info.circle.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text(explanation.explanation)
                                .font(.body)
                        }
                        
                        // Possible causes
                        if !explanation.possibleCauses.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Possible Causes", systemImage: "list.bullet")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                ForEach(explanation.possibleCauses, id: \.self) { cause in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(cause)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                        
                        // Suggested fixes
                        if !explanation.suggestedFixes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Suggested Fixes", systemImage: "wrench.and.screwdriver.fill")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                ForEach(explanation.suggestedFixes, id: \.self) { fix in
                                    Button(action: {
                                        if let command = extractCommand(from: fix) {
                                            onSelectFix(command)
                                        }
                                    }) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(fix)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                
                                                if let command = extractCommand(from: fix) {
                                                    Text(command)
                                                        .font(.system(.caption, design: .monospaced))
                                                        .foregroundColor(.blue)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.blue.opacity(0.1))
                                                        .cornerRadius(6)
                                                }
                                            }
                                            Spacer()
                                            if extractCommand(from: fix) != nil {
                                                Image(systemName: "arrow.right.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Unable to analyze error")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadExplanation()
        }
    }
    
    private func loadExplanation() {
        Task {
            do {
                let result = try await aiService.explainError(error, command: command, context: context)
                await MainActor.run {
                    explanation = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func extractCommand(from text: String) -> String? {
        // Try to find text between backticks or "Try:" prefix
        if let range = text.range(of: "`[^`]+`", options: .regularExpression) {
            let cmd = String(text[range])
            return cmd.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
        }
        
        if let range = text.range(of: "(?:Try:|Use:|Run:)\\s*(.+)$", options: .regularExpression) {
            let cmd = String(text[range])
            return cmd.replacingOccurrences(of: "^(?:Try:|Use:|Run:)\\s*", with: "", options: .regularExpression)
        }
        
        return nil
    }
}
