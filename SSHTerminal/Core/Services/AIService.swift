import Foundation
import Security

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isEnabled: Bool = false
    @Published var selectedModel: AIModel = .gpt4oMini
    @Published var selectedProvider: AIProvider = .openai
    @Published var totalTokensUsed: Int = 0
    @Published var estimatedCost: Double = 0.0
    @Published var isRateLimited: Bool = false
    @Published var rateLimitResetTime: Date?

    private let keychainService = KeychainService.shared

    // Configuration
    struct Config {
        static let openaiEndpoint = "https://api.openai.com/v1/chat/completions"
        static let ollamaEndpoint = "http://localhost:11434/api/chat"
        static let maxRequestsPerMinute = 20
        static let rateLimitWindowSeconds: TimeInterval = 60
        static let requestTimeoutSeconds: TimeInterval = 30
    }
    
    enum AIProvider: String, CaseIterable, Identifiable {
        case openai = "OpenAI"
        case ollama = "Ollama (Kali)"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .openai: return "OpenAI (Cloud)"
            case .ollama: return "Ollama (Kali - Free)"
            }
        }
        
        var requiresAPIKey: Bool {
            switch self {
            case .openai: return true
            case .ollama: return false
            }
        }
        
        var endpoint: String {
            switch self {
            case .openai: return Config.openaiEndpoint
            case .ollama: return Config.ollamaEndpoint
            }
        }
    }

    // Rate limiting state
    private var requestTimestamps: [Date] = []
    private let rateLimitQueue = DispatchQueue(label: "com.sshterminal.ratelimit")

    enum AIModel: String, CaseIterable, Identifiable {
        // OpenAI Models
        case gpt4o = "gpt-4o"
        case gpt4oMini = "gpt-4o-mini"
        case gpt4Turbo = "gpt-4-turbo"
        case gpt35Turbo = "gpt-3.5-turbo"
        
        // Ollama Models (Kali Server)
        case deepseekCoder = "deepseek-coder:6.7b"
        case dolphinMistral = "dolphin-mistral:7b-v2.8"
        case tinyllama = "tinyllama:latest"

        var id: String { rawValue }
        
        var provider: AIProvider {
            switch self {
            case .gpt4o, .gpt4oMini, .gpt4Turbo, .gpt35Turbo:
                return .openai
            case .deepseekCoder, .dolphinMistral, .tinyllama:
                return .ollama
            }
        }

        var displayName: String {
            switch self {
            case .gpt4o: return "GPT-4o (Most Capable)"
            case .gpt4oMini: return "GPT-4o Mini (Fast & Cheap)"
            case .gpt4Turbo: return "GPT-4 Turbo (Balanced)"
            case .gpt35Turbo: return "GPT-3.5 Turbo (Legacy)"
            case .deepseekCoder: return "DeepSeek Coder 6.7B (Free, Local)"
            case .dolphinMistral: return "Dolphin Mistral 7B (Free, Local)"
            case .tinyllama: return "TinyLlama 1.1B (Fast, Free)"
            }
        }

        var costPer1kInputTokens: Double {
            switch self {
            case .gpt4o: return 0.005
            case .gpt4oMini: return 0.00015
            case .gpt4Turbo: return 0.01
            case .gpt35Turbo: return 0.0005
            case .deepseekCoder, .dolphinMistral, .tinyllama: return 0.0 // Free!
            }
        }

        var costPer1kOutputTokens: Double {
            switch self {
            case .gpt4o: return 0.015
            case .gpt4oMini: return 0.0006
            case .gpt4Turbo: return 0.03
            case .gpt35Turbo: return 0.0015
            case .deepseekCoder, .dolphinMistral, .tinyllama: return 0.0 // Free!
            }
        }

        var maxContextLength: Int {
            switch self {
            case .gpt4o, .gpt4oMini: return 128_000
            case .gpt4Turbo: return 128_000
            case .gpt35Turbo: return 16_385
            case .deepseekCoder: return 16_384
            case .dolphinMistral: return 8_192
            case .tinyllama: return 2_048
            }
        }
    }
    
    enum AIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case rateLimitExceeded(retryAfter: TimeInterval?)
        case localRateLimitExceeded(waitSeconds: Int)
        case apiError(String)
        case networkError(Error)
        case requestTimeout

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured. Please add it in Settings."
            case .invalidResponse:
                return "Invalid response from OpenAI API"
            case .rateLimitExceeded(let retryAfter):
                if let seconds = retryAfter {
                    return "Rate limit exceeded. Try again in \(Int(seconds)) seconds."
                }
                return "Rate limit exceeded. Please try again later."
            case .localRateLimitExceeded(let waitSeconds):
                return "Too many requests. Please wait \(waitSeconds) seconds."
            case .apiError(let message):
                return "OpenAI API error: \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .requestTimeout:
                return "Request timed out. Please try again."
            }
        }
    }
    
    private init() {
        loadSettings()
    }
    
    // MARK: - API Key Management
    
    func setAPIKey(_ key: String) throws {
        try keychainService.save(password: key, for: "openai_api_key")
        isEnabled = !key.isEmpty
    }
    
    func getAPIKey() throws -> String {
        let key = try keychainService.retrieve(for: "openai_api_key")
        guard !key.isEmpty else {
            throw AIError.noAPIKey
        }
        return key
    }
    
    func hasAPIKey() -> Bool {
        if selectedProvider == .ollama {
            return true // Ollama doesn't require API key
        }
        return (try? !getAPIKey().isEmpty) ?? false
    }
    
    func removeAPIKey() {
        try? keychainService.delete(for: "openai_api_key")
        isEnabled = false
    }
    
    // MARK: - Command Suggestions
    
    func suggestCommands(context: CommandContext) async throws -> [CommandSuggestion] {
        guard isEnabled else { return [] }
        
        let prompt = """
        You are a helpful SSH terminal assistant. Based on the following context, suggest 3-5 useful bash commands the user might want to run next.
        
        Current Directory: \(context.currentDirectory)
        Operating System: \(context.osInfo)
        Last Command: \(context.lastCommand ?? "none")
        Last Output: \(context.lastOutput?.prefix(200) ?? "none")
        
        Respond with ONLY a JSON array of objects with "command" and "description" fields. Example:
        [{"command": "ls -la", "description": "List all files with details"}]
        """
        
        let response = try await makeAPIRequest(
            prompt: prompt,
            systemMessage: "You are a Unix command expert. Respond only with valid JSON.",
            maxTokens: 200,
            temperature: 0.3
        )
        
        return try parseCommandSuggestions(from: response)
    }
    
    // MARK: - Error Explanation
    
    func explainError(_ error: String, command: String, context: CommandContext) async throws -> ErrorExplanation {
        guard isEnabled else {
            return ErrorExplanation(
                explanation: "AI assistance disabled",
                possibleCauses: [],
                suggestedFixes: []
            )
        }
        
        let prompt = """
        A user ran this command and got an error:
        
        Command: \(command)
        Error: \(error)
        Directory: \(context.currentDirectory)
        OS: \(context.osInfo)
        
        Explain what went wrong in simple terms and suggest fixes. Respond with JSON:
        {
          "explanation": "Brief explanation",
          "possibleCauses": ["cause1", "cause2"],
          "suggestedFixes": ["fix1", "fix2"]
        }
        """
        
        let response = try await makeAPIRequest(
            prompt: prompt,
            systemMessage: "You are a helpful system administrator explaining errors to users.",
            maxTokens: 300,
            temperature: 0.4
        )
        
        return try parseErrorExplanation(from: response)
    }
    
    // MARK: - Natural Language to Command
    
    func naturalLanguageToCommand(_ input: String, context: CommandContext) async throws -> String {
        guard isEnabled else { throw AIError.noAPIKey }
        
        let prompt = """
        Convert this natural language request to a bash command:
        
        Request: \(input)
        Current Directory: \(context.currentDirectory)
        OS: \(context.osInfo)
        
        Respond with ONLY the bash command, no explanation or quotes.
        """
        
        let response = try await makeAPIRequest(
            prompt: prompt,
            systemMessage: "You are a Unix shell expert. Respond only with valid bash commands.",
            maxTokens: 100,
            temperature: 0.2
        )
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - AI Chat
    
    func chat(message: String, context: CommandContext, history: [ChatMessage] = []) async throws -> String {
        guard isEnabled else { throw AIError.noAPIKey }
        
        var messages: [[String: String]] = []
        
        // System context
        let systemContext = """
        You are a helpful SSH terminal assistant. The user is currently:
        - Directory: \(context.currentDirectory)
        - OS: \(context.osInfo)
        - Server: \(context.serverName)
        
        Help them with command questions, system administration, and troubleshooting.
        """
        messages.append(["role": "system", "content": systemContext])
        
        // History
        for msg in history {
            messages.append(["role": msg.role, "content": msg.content])
        }
        
        // Current message
        messages.append(["role": "user", "content": message])
        
        let response = try await makeAPIRequestWithMessages(
            messages: messages,
            maxTokens: 500,
            temperature: 0.7
        )
        
        return response
    }
    
    // MARK: - API Request Handler
    
    private func makeAPIRequest(
        prompt: String,
        systemMessage: String,
        maxTokens: Int,
        temperature: Double
    ) async throws -> String {
        let messages = [
            ["role": "system", "content": systemMessage],
            ["role": "user", "content": prompt]
        ]
        
        return try await makeAPIRequestWithMessages(
            messages: messages,
            maxTokens: maxTokens,
            temperature: temperature
        )
    }
    
    private func makeAPIRequestWithMessages(
        messages: [[String: String]],
        maxTokens: Int,
        temperature: Double
    ) async throws -> String {
        // Check local rate limit first
        try checkLocalRateLimit()

        // Use appropriate endpoint based on provider
        let endpoint = selectedProvider.endpoint
        guard let url = URL(string: endpoint) else {
            throw AIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Config.requestTimeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body based on provider
        var body: [String: Any]
        
        switch selectedProvider {
        case .openai:
            let apiKey = try getAPIKey()
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            body = [
                "model": selectedModel.rawValue,
                "messages": messages,
                "max_tokens": maxTokens,
                "temperature": temperature
            ]
            
        case .ollama:
            // Ollama format is slightly different
            body = [
                "model": selectedModel.rawValue,
                "messages": messages,
                "stream": false,
                "options": [
                    "temperature": temperature,
                    "num_predict": maxTokens
                ]
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Record this request for rate limiting
        recordRequest()

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Double($0) }
                handleAPIRateLimit(retryAfter: retryAfter)
                throw AIError.rateLimitExceeded(retryAfter: retryAfter)
            }

            guard httpResponse.statusCode == 200 else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIError.apiError(errorText)
            }

            // Parse response based on provider
            let content: String
            
            switch selectedProvider {
            case .openai:
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let messageContent = message["content"] as? String else {
                    throw AIError.invalidResponse
                }
                content = messageContent
                
                // Track OpenAI usage
                if let usage = json["usage"] as? [String: Any] {
                    let inputTokens = usage["prompt_tokens"] as? Int ?? 0
                    let outputTokens = usage["completion_tokens"] as? Int ?? 0
                    await updateUsageStats(inputTokens: inputTokens, outputTokens: outputTokens)
                }
                
            case .ollama:
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = json["message"] as? [String: Any],
                      let messageContent = message["content"] as? String else {
                    throw AIError.invalidResponse
                }
                content = messageContent
                
                // Track Ollama usage (free, but still count for stats)
                if let evalCount = json["eval_count"] as? Int {
                    await updateUsageStats(inputTokens: 0, outputTokens: evalCount)
                }
            }

            return content
        } catch let error as AIError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw AIError.requestTimeout
        } catch {
            throw AIError.networkError(error)
        }
    }

    // MARK: - Rate Limiting

    private func checkLocalRateLimit() throws {
        rateLimitQueue.sync {
            // Clean up old timestamps
            let cutoff = Date().addingTimeInterval(-Config.rateLimitWindowSeconds)
            requestTimestamps = requestTimestamps.filter { $0 > cutoff }
        }

        let currentCount = rateLimitQueue.sync { requestTimestamps.count }

        if currentCount >= Config.maxRequestsPerMinute {
            let oldestRequest = rateLimitQueue.sync { requestTimestamps.first }
            let waitTime = Int((oldestRequest?.addingTimeInterval(Config.rateLimitWindowSeconds).timeIntervalSinceNow ?? 0) + 1)
            throw AIError.localRateLimitExceeded(waitSeconds: max(1, waitTime))
        }
    }

    private func recordRequest() {
        rateLimitQueue.sync {
            requestTimestamps.append(Date())
        }
    }

    private func handleAPIRateLimit(retryAfter: TimeInterval?) {
        isRateLimited = true
        if let seconds = retryAfter {
            rateLimitResetTime = Date().addingTimeInterval(seconds)

            // Auto-reset after the specified time
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                self.isRateLimited = false
                self.rateLimitResetTime = nil
            }
        }
    }

    /// Get current rate limit status
    func getRateLimitStatus() -> (requestsRemaining: Int, windowResetIn: TimeInterval) {
        let cutoff = Date().addingTimeInterval(-Config.rateLimitWindowSeconds)
        let recentRequests = rateLimitQueue.sync {
            requestTimestamps.filter { $0 > cutoff }
        }

        let remaining = max(0, Config.maxRequestsPerMinute - recentRequests.count)
        let oldestInWindow = recentRequests.first
        let resetIn = oldestInWindow?.addingTimeInterval(Config.rateLimitWindowSeconds).timeIntervalSinceNow ?? 0

        return (remaining, max(0, resetIn))
    }
    
    // MARK: - Response Parsing
    
    private func parseCommandSuggestions(from json: String) throws -> [CommandSuggestion] {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8),
              let array = try JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        
        return array.compactMap { dict in
            guard let command = dict["command"],
                  let description = dict["description"] else {
                return nil
            }
            return CommandSuggestion(command: command, description: description)
        }
    }
    
    private func parseErrorExplanation(from json: String) throws -> ErrorExplanation {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8),
              let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let explanation = dict["explanation"] as? String,
              let causes = dict["possibleCauses"] as? [String],
              let fixes = dict["suggestedFixes"] as? [String] else {
            throw AIError.invalidResponse
        }
        
        return ErrorExplanation(
            explanation: explanation,
            possibleCauses: causes,
            suggestedFixes: fixes
        )
    }
    
    // MARK: - Settings & Stats
    
    private func loadSettings() {
        isEnabled = hasAPIKey()
        
        if let modelRaw = UserDefaults.standard.string(forKey: "ai_selected_model"),
           let model = AIModel(rawValue: modelRaw) {
            selectedModel = model
        }
        
        totalTokensUsed = UserDefaults.standard.integer(forKey: "ai_total_tokens")
        estimatedCost = UserDefaults.standard.double(forKey: "ai_estimated_cost")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(selectedModel.rawValue, forKey: "ai_selected_model")
        UserDefaults.standard.set(totalTokensUsed, forKey: "ai_total_tokens")
        UserDefaults.standard.set(estimatedCost, forKey: "ai_estimated_cost")
    }
    
    private func updateUsageStats(inputTokens: Int, outputTokens: Int) {
        totalTokensUsed += inputTokens + outputTokens
        let inputCost = Double(inputTokens) / 1000.0 * selectedModel.costPer1kInputTokens
        let outputCost = Double(outputTokens) / 1000.0 * selectedModel.costPer1kOutputTokens
        estimatedCost += inputCost + outputCost
        saveSettings()
    }
    
    func resetStats() {
        totalTokensUsed = 0
        estimatedCost = 0.0
        saveSettings()
    }
}

// MARK: - Supporting Models

struct CommandContext {
    let currentDirectory: String
    let osInfo: String
    let serverName: String
    let lastCommand: String?
    let lastOutput: String?
}

struct CommandSuggestion: Identifiable {
    let id = UUID()
    let command: String
    let description: String
}

struct ErrorExplanation {
    let explanation: String
    let possibleCauses: [String]
    let suggestedFixes: [String]
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp: Date
    
    init(role: String, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
