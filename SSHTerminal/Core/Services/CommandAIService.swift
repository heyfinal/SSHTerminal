import Foundation

/// Lightweight AI service for natural language → bash command conversion
/// Uses local Ollama server (deepseek-coder) for fast, free inference
@MainActor
class CommandAIService: ObservableObject {
    static let shared = CommandAIService()
    
    @Published var isEnabled: Bool = true
    
    // Ollama server on Kali
    private let ollamaEndpoint = "http://***REMOVED***:11434/api/generate"
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
        guard let url = URL(string: "http://***REMOVED***:11434/api/tags") else {
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
            "network": "ip addr show",
            "wifi": "iwconfig",
            "disk": "df -h",
            "memory": "free -h",
            "cpu": "top -bn1 | head -20",
            "processes": "ps aux | head -20",
            "users": "who",
            "ports": "netstat -tuln",
            "logs": "tail -f /var/log/syslog",
            "docker": "docker ps -a"
        ]
        
        return templates[keyword.lowercased()]
    }
}
