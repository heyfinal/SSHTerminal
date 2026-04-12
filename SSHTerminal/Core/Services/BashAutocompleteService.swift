import Foundation
import Combine

struct AutocompleteSuggestion: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let displayText: String
    let kind: Kind

    enum Kind {
        case command, path, history, argument
    }
}

@MainActor
class BashAutocompleteService: ObservableObject {
    static let shared = BashAutocompleteService()

    @Published var suggestions: [AutocompleteSuggestion] = []

    var activeSession: SSHSession?

    private var inputBuffer: String = ""
    private var awaitingEscape = false
    private var escapeBuffer: [UInt8] = []
    private var pathTask: Task<Void, Never>?
    private var updateDebounce: Task<Void, Never>?

    private init() {}

    // MARK: - Input Tracking

    func processInputBytes(_ bytes: [UInt8]) {
        for byte in bytes {
            processByte(byte)
        }
    }

    private func processByte(_ byte: UInt8) {
        if awaitingEscape {
            escapeBuffer.append(byte)
            // Final byte of ANSI escape is in 0x40...0x7E range
            if byte >= 0x40 && byte <= 0x7E {
                handleEscapeSequence(escapeBuffer)
                awaitingEscape = false
                escapeBuffer = []
            }
            return
        }

        switch byte {
        case 0x1b: // ESC
            awaitingEscape = true
            escapeBuffer = []

        case 0x0d, 0x0a: // Enter
            inputBuffer = ""
            clearSuggestions()

        case 0x7f, 0x08: // Backspace / DEL
            if !inputBuffer.isEmpty { inputBuffer.removeLast() }
            scheduleUpdate()

        case 0x03, 0x04, 0x15, 0x17: // Ctrl+C/D/U/W — clear line
            inputBuffer = ""
            clearSuggestions()

        case 0x09: // Tab — always refresh
            scheduleUpdate()

        case 0x20...0x7e: // Printable ASCII
            if let ch = String(bytes: [byte], encoding: .utf8) {
                inputBuffer.append(ch)
                scheduleUpdate()
            }

        default:
            break
        }
    }

    private func handleEscapeSequence(_ seq: [UInt8]) {
        // Arrow keys (up/down) → user navigating history, clear our buffer
        if seq.first == 0x5b, let key = seq.dropFirst().first, (key == 0x41 || key == 0x42) {
            inputBuffer = ""
            clearSuggestions()
        }
    }

    func clearBuffer() {
        inputBuffer = ""
        clearSuggestions()
    }

    // MARK: - Debounced Update

    private func scheduleUpdate() {
        updateDebounce?.cancel()
        updateDebounce = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
            if !Task.isCancelled { updateSuggestions() }
        }
    }

    // MARK: - Suggestion Logic

    private func updateSuggestions() {
        let line = inputBuffer
        guard !line.isEmpty else { clearSuggestions(); return }

        // Split keeping trailing space awareness
        let hasTrailingSpace = line.hasSuffix(" ")
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let currentWord = hasTrailingSpace ? "" : (tokens.last ?? "")
        let isFirstToken = tokens.count <= 1 && !hasTrailingSpace

        if isFirstToken {
            suggestions = commandCompletions(for: currentWord)
            pathTask?.cancel()
        } else if currentWord.isEmpty {
            // Just typed a space — show argument hints for the command
            let cmd = tokens.first ?? ""
            suggestions = argumentHints(for: cmd, prefix: "")
            pathTask?.cancel()
        } else if looksLikePath(currentWord) {
            triggerPathCompletion(prefix: currentWord)
        } else {
            let cmd = tokens.first ?? ""
            suggestions = argumentHints(for: cmd, prefix: currentWord)
            pathTask?.cancel()
        }
    }

    private func clearSuggestions() {
        pathTask?.cancel()
        updateDebounce?.cancel()
        suggestions = []
    }

    // MARK: - Command Completions

    private func commandCompletions(for prefix: String) -> [AutocompleteSuggestion] {
        guard !prefix.isEmpty else { return [] }

        var seen = Set<String>()
        var result: [AutocompleteSuggestion] = []

        // History first
        for cmd in CommandHistory.shared.uniqueCommands() where cmd.lowercased().hasPrefix(prefix.lowercased()) {
            if seen.insert(cmd).inserted {
                result.append(AutocompleteSuggestion(text: cmd, displayText: cmd, kind: .history))
            }
            if result.count >= 5 { break }
        }

        // Static list
        for cmd in staticCommands where cmd.hasPrefix(prefix) {
            if seen.insert(cmd).inserted {
                result.append(AutocompleteSuggestion(text: cmd, displayText: cmd, kind: .command))
            }
            if result.count >= 12 { break }
        }

        return result
    }

    // MARK: - Argument Hints

    private func argumentHints(for command: String, prefix: String) -> [AutocompleteSuggestion] {
        guard let args = commandArgMap[command] else { return [] }
        let filtered = prefix.isEmpty ? args : args.filter { $0.hasPrefix(prefix) }
        return filtered.prefix(8).map {
            AutocompleteSuggestion(text: $0, displayText: $0, kind: .argument)
        }
    }

    // MARK: - Path Completion via SSH

    private func looksLikePath(_ word: String) -> Bool {
        word.hasPrefix("/") || word.hasPrefix("~/") || word.hasPrefix("./") ||
        word.hasPrefix("../") || word == "~" || word == "." || word == ".."
    }

    private func triggerPathCompletion(prefix: String) {
        pathTask?.cancel()
        pathTask = Task {
            guard let session = activeSession else { return }
            let safe = prefix.replacingOccurrences(of: "'", with: "'\\''")
            let cmd = "bash -c \"compgen -f '\(safe)' 2>/dev/null | head -25\""
            guard let raw = try? await SSHService.shared.executeCommand(cmd, in: session) else { return }
            guard !Task.isCancelled else { return }

            let items = raw.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { AutocompleteSuggestion(text: $0, displayText: $0, kind: .path) }

            self.suggestions = items
        }
    }

    // MARK: - Insertion Bytes

    /// Bytes to send to PTY to replace current word with suggestion
    func insertionBytes(for suggestion: AutocompleteSuggestion) -> [UInt8] {
        let line = inputBuffer
        let hasTrailingSpace = line.hasSuffix(" ")
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let currentWord = hasTrailingSpace ? "" : (tokens.last ?? "")

        // Delete current word with backspaces
        let backspaces = [UInt8](repeating: 0x7f, count: currentWord.count)
        var insertion = Array(suggestion.text.utf8)

        // Append space after commands/arguments; slash already in path if dir
        switch suggestion.kind {
        case .command, .argument:
            insertion.append(0x20)
        case .path:
            if !suggestion.text.hasSuffix("/") {
                insertion.append(0x20)
            }
        case .history:
            insertion.append(0x20)
        }

        return backspaces + insertion
    }

    // MARK: - Static Data

    private let staticCommands: [String] = [
        "alias", "ansible", "apt", "apt-get", "at", "awk",
        "base64", "bash", "bat", "bc", "bg", "blkid", "brew", "bzip2",
        "cal", "cargo", "cat", "cd", "chgrp", "chmod", "chown", "cmp", "col",
        "comm", "cp", "crontab", "curl", "cut",
        "date", "dc", "dd", "df", "diff", "dig", "dmesg", "dnf", "docker",
        "docker-compose", "du",
        "echo", "emacs", "env", "eval", "exec", "expand", "export",
        "false", "fdisk", "fg", "file", "find", "fish", "free", "fzf",
        "gdb", "gemini", "git", "gzip", "gunzip",
        "head", "help", "hexdump", "history", "hostname", "htop",
        "ifconfig", "info", "iostat", "ip", "iotop", "iptables",
        "join", "journalctl",
        "kill", "killall", "kubectl",
        "la", "less", "ll", "ln", "locate", "log", "lsblk", "lsof", "ltrace",
        "ls", "lsblk",
        "man", "md5sum", "mkdir", "more", "mount", "mv",
        "nano", "netstat", "nmap", "node", "nohup", "npm",
        "od", "openssl",
        "pacman", "paste", "patch", "perl", "ping", "pip", "pip3", "pkill",
        "printf", "ps", "pwd", "python", "python3",
        "read", "rm", "rmdir", "rsync", "ruby",
        "scp", "screen", "sed", "service", "sftp", "sh", "sha256sum",
        "sort", "source", "ss", "ssh", "stat", "strace", "strings", "sudo",
        "systemctl",
        "tail", "tar", "tee", "terraform", "test", "tmux", "top", "touch",
        "tr", "traceroute", "true", "type",
        "ufw", "umount", "uname", "unexpand", "uniq", "unzip", "uptime",
        "useradd", "userdel", "usermod",
        "valgrind", "vi", "vim", "visudo", "vmstat",
        "watch", "wc", "wget", "whereis", "which", "who",
        "xargs", "xxd", "xz",
        "yum",
        "zip", "zsh"
    ].sorted()

    private let commandArgMap: [String: [String]] = [
        "ls": ["-la", "-lh", "-lt", "-ltr", "-a", "-l", "-h", "-t", "-r", "-R",
               "--color=auto", "--color", "-1", "-S", "/etc", "/var", "/home", "/tmp"],
        "cd": ["/", "~", "..", "../..", "/etc", "/var/log", "/home", "/tmp",
               "/usr/local", "/opt", "/etc/ssh", "/var/www"],
        "grep": ["-r", "-i", "-n", "-v", "-l", "-c", "-E", "-rn", "-ri",
                 "-A2", "-B2", "-C2", "--include=*.py", "--include=*.go"],
        "find": [".", "/", "-name", "-type f", "-type d", "-size", "-mtime",
                 "-exec", "-maxdepth 1", "-maxdepth 2", "-newer", "-perm", "-user"],
        "ps": ["aux", "-ef", "auxf", "-a", "-u", "-x", "--forest", "aux | grep"],
        "kill": ["-9", "-15", "-HUP", "-INT", "-TERM", "-KILL", "-SIGTERM"],
        "chmod": ["755", "644", "777", "600", "400", "644 -R", "755 -R", "+x", "u+x"],
        "chown": ["-R", "root:root", "www-data:www-data"],
        "tar": ["-czf", "-xzf", "-cjf", "-xjf", "-xvf", "-tvf", "-czv",
                "--list", "--extract"],
        "git": ["status", "log", "log --oneline", "diff", "add .", "add -A",
                "commit -m", "push", "push origin", "pull", "clone",
                "checkout", "checkout -b", "branch", "branch -a",
                "merge", "rebase", "stash", "fetch", "remote -v",
                "reset --soft HEAD~1", "log --graph --oneline"],
        "docker": ["ps", "ps -a", "images", "run -it", "run -d",
                   "exec -it", "stop", "rm", "rmi", "build -t",
                   "pull", "logs -f", "inspect", "network ls",
                   "volume ls", "system prune -f"],
        "kubectl": ["get pods", "get services", "get nodes", "describe pod",
                    "apply -f", "delete -f", "logs -f", "exec -it", "port-forward"],
        "systemctl": ["start", "stop", "restart", "status", "enable",
                      "disable", "reload", "list-units", "daemon-reload",
                      "is-active", "is-enabled"],
        "apt-get": ["update", "upgrade", "-y upgrade", "install", "remove",
                    "purge", "autoremove", "clean", "dist-upgrade"],
        "apt": ["update", "upgrade", "install", "remove", "search", "show", "list --installed"],
        "ssh": ["-p 22", "-i ~/.ssh/id_rsa", "-L", "-R", "-D", "-N",
                "-v", "-o StrictHostKeyChecking=no"],
        "curl": ["-X GET", "-X POST", "-X PUT", "-X DELETE",
                 "-H 'Content-Type: application/json'",
                 "-d", "-o", "-L", "-s", "-v", "-k", "-u", "--data"],
        "vim": ["+", "-n", "-R", "-c", "+/", "+:%s/"],
        "sed": ["-i", "-n", "-e", "-r", "-E",
                "'s/old/new/g'", "'s/^/# /'", "'/pattern/d'"],
        "awk": ["-F:", "-F,", "-F\\t",
                "'{print $1}'", "'{print $NF}'",
                "'{sum+=$1}END{print sum}'",
                "NR>1{print}'"],
        "df": ["-h", "-H", "-T", "-i", "--total", "-h --total"],
        "du": ["-sh", "-sh *", "-h", "-s", "--max-depth=1", "-ah | sort -rh | head -20"],
        "top": ["-bn1", "-u", "-p", "-d 1"],
        "netstat": ["-tuln", "-tulnp", "-an", "-r", "-s", "-tp"],
        "ss": ["-tuln", "-tulnp", "-an", "-s", "-tp", "-4"],
        "ip": ["addr", "addr show", "link", "link show", "route",
               "route show", "neigh"],
        "ping": ["-c 3", "-c 5", "-i 0.2", "-W 1", "-s 64"],
        "journalctl": ["-n 50", "-f", "-u", "-b", "--since today",
                       "--until now", "-p err", "--no-pager", "-xe"],
        "sudo": ["-u", "-l", "-s", "-i", "-k", "su -"],
        "crontab": ["-e", "-l", "-r", "-u root -l"],
        "rsync": ["-avz", "-avzP", "--progress", "--delete",
                  "--exclude=.git", "-n", "--dry-run"],
        "python3": ["-m http.server", "-m json.tool", "-c", "-i",
                    "-m venv venv", "-m pip install"],
        "pip3": ["install", "install -r requirements.txt",
                 "list", "freeze", "uninstall", "show"],
        "tmux": ["new", "new -s", "attach", "attach -t", "ls",
                 "kill-session -t", "split-window", "split-window -h"],
        "screen": ["-S", "-r", "-ls", "-d -r", "-X quit"],
    ]
}
