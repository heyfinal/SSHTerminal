import SwiftUI

struct AISettingsView: View {
    @StateObject private var aiService = AIService.shared
    @State private var apiKey: String = ""
    @State private var showingKeyInput: Bool = false
    @State private var saveMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Status Section
                Section {
                    HStack {
                        Image(systemName: aiService.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(aiService.isEnabled ? .green : .red)
                        Text("AI Features")
                        Spacer()
                        Text(aiService.isEnabled ? "Enabled" : "Disabled")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Status")
                }
                
                // API Key Section
                Section {
                    if aiService.hasAPIKey() {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text("••••••••")
                                .foregroundColor(.secondary)
                            Button("Change") {
                                showingKeyInput = true
                            }
                            .font(.caption)
                        }
                        
                        Button("Remove API Key", role: .destructive) {
                            aiService.removeAPIKey()
                            saveMessage = "API key removed"
                        }
                    } else {
                        Button("Add API Key") {
                            showingKeyInput = true
                        }
                    }
                    
                    if let message = saveMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Get your API key from platform.openai.com/api-keys")
                }
                
                // Model Selection
                Section {
                    Picker("Model", selection: $aiService.selectedModel) {
                        ForEach(AIService.AIModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }

                    HStack {
                        Text("Input Cost (per 1K)")
                        Spacer()
                        Text("$\(String(format: "%.5f", aiService.selectedModel.costPer1kInputTokens))")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Output Cost (per 1K)")
                        Spacer()
                        Text("$\(String(format: "%.5f", aiService.selectedModel.costPer1kOutputTokens))")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Max Context")
                        Spacer()
                        Text("\(aiService.selectedModel.maxContextLength / 1000)K tokens")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Model Selection")
                } footer: {
                    Text("GPT-4o is most capable. GPT-4o Mini offers great balance of cost and quality.")
                }
                
                // Usage Stats
                Section {
                    HStack {
                        Text("Total Tokens Used")
                        Spacer()
                        Text("\(aiService.totalTokensUsed)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text("$\(String(format: "%.2f", aiService.estimatedCost))")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Reset Stats") {
                        aiService.resetStats()
                    }
                } header: {
                    Text("Usage Statistics")
                }
                
                // Features
                Section {
                    FeatureRow(
                        icon: "lightbulb.fill",
                        title: "Command Suggestions",
                        description: "Get smart command recommendations",
                        enabled: aiService.isEnabled
                    )
                    
                    FeatureRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Error Explanations",
                        description: "Understand and fix command errors",
                        enabled: aiService.isEnabled
                    )
                    
                    FeatureRow(
                        icon: "message.fill",
                        title: "AI Chat Assistant",
                        description: "Ask questions about systems",
                        enabled: aiService.isEnabled
                    )
                    
                    FeatureRow(
                        icon: "wand.and.stars",
                        title: "Natural Language",
                        description: "Convert plain text to commands",
                        enabled: aiService.isEnabled
                    )
                } header: {
                    Text("Features")
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingKeyInput) {
                APIKeyInputView(onSave: { key in
                    do {
                        try aiService.setAPIKey(key)
                        saveMessage = "API key saved successfully"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            saveMessage = nil
                        }
                    } catch {
                        saveMessage = "Failed to save: \(error.localizedDescription)"
                    }
                    showingKeyInput = false
                })
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let enabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(enabled ? .blue : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(enabled ? .green : .gray)
        }
    }
}

struct APIKeyInputView: View {
    @State private var apiKey: String = ""
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("sk-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your API key is stored securely in the iOS Keychain.")
                        Text("Get your key from: platform.openai.com/api-keys")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(apiKey)
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AISettingsView()
}
