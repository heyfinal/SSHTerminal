import SwiftUI

struct AIAssistantView: View {
    @StateObject private var aiService = AIService.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    let context: CommandContext
    let onInsertCommand: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    messages.removeAll()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Ask me anything about commands, systems, or troubleshooting!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Try asking:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ForEach(["How do I find large files?", "Explain file permissions", "How to check disk space?"], id: \.self) { example in
                                        Button(action: { inputText = example }) {
                                            Text("• \(example)")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(messages) { message in
                                ChatBubble(message: message, onInsertCommand: onInsertCommand)
                                    .id(message.id)
                            }
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Error message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Dismiss") {
                        errorMessage = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
            }
            
            Divider()
            
            // Input
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? .gray : .blue)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .onAppear {
            if !aiService.hasAPIKey() {
                errorMessage = "Configure OpenAI API key in Settings to use AI features"
            }
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        let userMessage = ChatMessage(role: "user", content: message)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let response = try await aiService.chat(
                    message: message,
                    context: context,
                    history: messages
                )
                
                let aiMessage = ChatMessage(role: "assistant", content: response)
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let onInsertCommand: (String) -> Void
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if message.role == "assistant" {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    Text(message.role == "user" ? "You" : "AI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.role == "user" ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .cornerRadius(16)
                
                // Extract and show commands
                if message.role == "assistant" {
                    ForEach(extractCommands(from: message.content), id: \.self) { command in
                        Button(action: { onInsertCommand(command) }) {
                            HStack {
                                Image(systemName: "terminal")
                                    .font(.caption)
                                Text(command)
                                    .font(.caption.monospaced())
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(maxWidth: 280, alignment: message.role == "user" ? .trailing : .leading)
            
            if message.role == "assistant" {
                Spacer()
            }
        }
    }
    
    private func extractCommands(from text: String) -> [String] {
        let pattern = "`([^`]+)`"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        return results.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }.filter { $0.contains(" ") || $0.contains("-") }
    }
}
