//
//  Snippet.swift
//  SSHTerminal
//
//  Phase 5: Command Snippet Models
//

import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var category: String
    var tags: [String]
    var description: String
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var lastUsedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        category: String = "General",
        tags: [String] = [],
        description: String = "",
        isFavorite: Bool = false,
        usageCount: Int = 0,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.category = category
        self.tags = tags
        self.description = description
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
    
    var processedCommand: String {
        // Replace common placeholders
        var cmd = command
        cmd = cmd.replacingOccurrences(of: "{date}", with: dateString)
        cmd = cmd.replacingOccurrences(of: "{time}", with: timeString)
        cmd = cmd.replacingOccurrences(of: "{datetime}", with: datetimeString)
        return cmd
    }
    
    var hasVariables: Bool {
        command.contains("{") && command.contains("}")
    }
    
    var variables: [String] {
        let pattern = "\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let matches = regex.matches(in: command, range: NSRange(command.startIndex..., in: command))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: command) else { return nil }
            return String(command[range])
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private var datetimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Default Snippets

extension Snippet {
    static let defaultSnippets: [Snippet] = [
        Snippet(
            name: "System Info",
            command: "uname -a && uptime",
            category: "System",
            tags: ["info", "system"],
            description: "Display system information and uptime"
        ),
        Snippet(
            name: "Disk Usage",
            command: "df -h",
            category: "System",
            tags: ["disk", "storage"],
            description: "Show disk space usage"
        ),
        Snippet(
            name: "Memory Usage",
            command: "free -h",
            category: "System",
            tags: ["memory", "ram"],
            description: "Display memory statistics"
        ),
        Snippet(
            name: "Network Interfaces",
            command: "ip addr show",
            category: "Network",
            tags: ["network", "ip"],
            description: "List all network interfaces"
        ),
        Snippet(
            name: "Active Connections",
            command: "netstat -tunap",
            category: "Network",
            tags: ["network", "connections"],
            description: "Show active network connections"
        ),
        Snippet(
            name: "Process List",
            command: "ps aux | head -20",
            category: "Processes",
            tags: ["process", "ps"],
            description: "List running processes"
        ),
        Snippet(
            name: "Find Large Files",
            command: "find . -type f -size +100M -exec ls -lh {} \\;",
            category: "Files",
            tags: ["find", "files"],
            description: "Find files larger than 100MB"
        ),
        Snippet(
            name: "Git Status",
            command: "git status && git log --oneline -5",
            category: "Git",
            tags: ["git", "version-control"],
            description: "Show git status and recent commits"
        ),
        Snippet(
            name: "Docker Containers",
            command: "docker ps -a",
            category: "Docker",
            tags: ["docker", "containers"],
            description: "List all Docker containers"
        ),
        Snippet(
            name: "Service Status",
            command: "systemctl status {service}",
            category: "System",
            tags: ["systemd", "service"],
            description: "Check systemd service status"
        ),
        Snippet(
            name: "Tail Log File",
            command: "tail -f {logfile}",
            category: "Logs",
            tags: ["logs", "monitoring"],
            description: "Follow log file in real-time"
        ),
        Snippet(
            name: "Port Scan",
            command: "nmap -sV {host}",
            category: "Network",
            tags: ["network", "security"],
            description: "Scan host for open ports"
        ),
        Snippet(
            name: "Archive Directory",
            command: "tar -czf {name}-{date}.tar.gz {directory}",
            category: "Files",
            tags: ["backup", "archive"],
            description: "Create compressed archive"
        ),
        Snippet(
            name: "CPU Temperature",
            command: "sensors | grep -i temp",
            category: "System",
            tags: ["hardware", "temperature"],
            description: "Display CPU temperature"
        ),
        Snippet(
            name: "SSH Tunnel",
            command: "ssh -L {local_port}:localhost:{remote_port} {user}@{host}",
            category: "Network",
            tags: ["ssh", "tunnel"],
            description: "Create SSH tunnel"
        )
    ]
}
