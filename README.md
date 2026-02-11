# SSHTerminal

Modern iOS SSH terminal with native PTY integration and AI-powered command assistance.

## Features

### 🖥️ Native Terminal Emulation
- **SwiftTerm Integration**: Full ANSI escape code support
- **PTY Sessions**: Proper terminal dimensions (no more 80-column wrapping!)
- **Bidirectional Communication**: Real-time terminal I/O
- **Custom Keyboard Toolbar**: Tab, Esc, arrow keys, Ctrl shortcuts

### 🤖 AI Command Assistant (Free!)
- **Natural Language → Bash**: Type "show disk space" → `df -h`
- **Local Ollama Server**: 100% free using Kali server
- **DeepSeek Coder 6.7B**: Optimized for code/command generation
- **Quick Templates**: Instant commands for network, disk, memory, cpu, etc.
- **Magic Wand Button**: ⭐ in keyboard toolbar for easy access

### 🔐 SSH Features
- Password and key-based authentication
- Host key verification and storage
- Multiple server profiles
- Session management

## Quick Start

1. **Add Server**: Tap "+" to add SSH credentials
2. **Connect**: Tap server to connect
3. **Use AI**: Tap ⭐ button and type natural language
4. **Execute**: Commands auto-execute or use keyboard shortcuts

## AI Command Examples

```
"network config"     → ip addr show
"disk space"         → df -h
"memory usage"       → free -h
"running processes"  → ps aux
"wifi status"        → iwconfig
```

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

- [Citadel](https://github.com/orlandos-nl/Citadel) (forked for PTY API access)
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) (native terminal emulator)
- Ollama server (optional - for AI features)

## Architecture

### Core Services
- **SSHService**: Connection management, PTY session creation
- **PTYTerminalView**: SwiftTerm wrapper with TerminalViewDelegate
- **CommandAIService**: Natural language → bash conversion

### Key Technical Details
- Uses local Citadel fork with exposed PTY APIs
- `@unchecked Sendable` concurrency model for NIO types
- Ollama endpoint: `http://***REMOVED***:11434`
- Model: `deepseek-coder:6.7b`

## Development

```bash
# Clone
git clone https://github.com/heyfinal/SSHTerminal.git

# Open in Xcode
open SSHTerminal.xcodeproj

# Build & Run
⌘ + R
```

## Documentation

- [Development History](docs/DEVELOPMENT_HISTORY.md)
- [Build & Launch Guide](docs/BUILD_AND_LAUNCH.md)
- [Archived Logs](docs/archive/)

## Testing

Test server credentials (Kali):
- Host: `***REMOVED***`
- User: `daniel`
- Password: `***REMOVED***`

## Recent Updates

### v0.2.0 (Feb 11, 2026)
- ✅ Added Ollama AI command conversion
- ✅ Magic wand button in keyboard toolbar
- ✅ Free, local LLM integration

### v0.1.0 (Feb 11, 2026)
- ✅ Fixed terminal formatting with PTY integration
- ✅ SwiftTerm native terminal emulator
- ✅ Proper terminal dimensions
- ✅ Bidirectional SSH ↔ Terminal communication

## License

MIT

## Author

Daniel (@heyfinal)

---

**Note**: This app uses a local Ollama server for AI features. The server runs on a Kali machine at ***REMOVED*** with deepseek-coder:6.7b, dolphin-mistral:7b-v2.8, and tinyllama models.
