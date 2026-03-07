import Foundation

/// Lightweight AI service for natural language → bash command conversion
/// Uses local Ollama server (deepseek-coder) for fast, free inference
@MainActor
class CommandAIService: ObservableObject {
    static let shared = CommandAIService()
    
    @Published var isEnabled: Bool = true
    
    // Ollama server (configurable via UserDefaults)
    private var ollamaHost: String {
        UserDefaults.standard.string(forKey: "ollama_host") ?? "localhost"
    }
    private var ollamaPort: Int {
        let port = UserDefaults.standard.integer(forKey: "ollama_port")
        return port > 0 ? port : 11434
    }
    private var ollamaEndpoint: String {
        "http://\(ollamaHost):\(ollamaPort)/api/generate"
    }
    private var ollamaTagsEndpoint: String {
        "http://\(ollamaHost):\(ollamaPort)/api/tags"
    }
    private let model = "deepseek-coder:6.7b" // Best for code/commands
    
    private init() {
        // Check if Ollama server is reachable
        Task {
            await checkServerHealth()
        }
    }
    
    /// Convert natural language to bash command
    func textToCommand(_ input: String) async -> String? {
        guard isEnabled else { return nil }
        
        let prompt = """
        Convert this to a bash command. Reply with ONLY the command, no explanation or markdown:
        
        \(input)
        """
        
        return await generateCommand(prompt: prompt)
    }
    
    /// Generate bash command from prompt
    private func generateCommand(prompt: String) async -> String? {
        guard let url = URL(string: ollamaEndpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10 // Fast timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.1, // Low temperature for deterministic output
                "num_predict": 50   // Short responses only
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isEnabled = false
                return nil
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseText = json["response"] as? String else {
                return nil
            }
            
            // Clean up response (remove markdown, quotes, etc)
            let cleaned = responseText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```bash", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            print("❌ Ollama request failed: \(error)")
            isEnabled = false
            return nil
        }
    }
    
    /// Check if Ollama server is healthy
    private func checkServerHealth() async {
        guard let url = URL(string: ollamaTagsEndpoint) else {
            isEnabled = false
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                isEnabled = httpResponse.statusCode == 200
            }
        } catch {
            isEnabled = false
        }
    }
    
    /// Common command templates (instant, no AI needed)
    func quickCommand(for keyword: String) -> String? {
        let templates: [String: String] = [
            "network": "ip addr show 2>/dev/null || ifconfig",
            "disk": "df -h",
            "memory": "free -h 2>/dev/null || vm_stat",
            "cpu": "top -bn1 2>/dev/null | head -20 || top -l1 | head -20",
            "processes": "ps aux | head -20",
            "users": "who",
            "ports": "ss -tuln 2>/dev/null || netstat -an | grep LISTEN",
            "logs": "journalctl -n 50 --no-pager 2>/dev/null || tail -50 /var/log/syslog 2>/dev/null || log show --last 5m --style compact | tail -50",
            "docker": "docker ps -a"
        ]

        return templates[keyword.lowercased()]
    }
}
