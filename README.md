```
                                                   
          |    |                   o          |    
,---.,---.|---.|--- ,---.,---.,-.-..,---.,---.|    
`---.`---.|   ||    |---'|    | | |||   |,---||    
`---'`---'`   '`---'`---'`    ` ' '``   '`---^`---'
                                                   
```

# 🔐 SSHTerminal

Modern iOS SSH terminal with **native PTY integration** and **AI-powered command assistance**.

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build](https://github.com/heyfinal/SSHTerminal/actions/workflows/ios-build-test.yml/badge.svg)](https://github.com/heyfinal/SSHTerminal/actions)
[![GitHub Stars](https://img.shields.io/github/stars/heyfinal/SSHTerminal?style=social)](https://github.com/heyfinal/SSHTerminal/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/heyfinal/SSHTerminal?style=social)](https://github.com/heyfinal/SSHTerminal/network/members)

> 🎯 **The ONLY free iOS SSH terminal with local AI command assistance**  
> 💰 **$0 forever** vs. Termius ($100/yr), Blink ($20/yr), Prompt ($15)  
> 🤖 **NO API keys needed** - runs 100% locally with Ollama

Transform natural language into bash commands using local AI - **100% free!**

```
You: "show me disk space"
AI:  df -h
```

## ✨ Features

### 🤖 AI Command Assistant
- **Natural Language → Bash**: Type plain English, get bash commands
- **Local Ollama Server**: No API costs, 100% free forever
- **DeepSeek Coder 6.7B**: Optimized for code/command generation
- **Quick Templates**: Instant commands (network, disk, memory, cpu, wifi)
- **Magic Wand Button**: ⭐ in keyboard toolbar for easy access
- **Privacy**: Everything runs locally, no data sent to cloud

### 🖥️ Native Terminal Emulation
- **SwiftTerm Integration**: Full ANSI escape code support
- **Proper PTY Sessions**: Terminal dimensions adapt to screen width
- **No More 80-Column Wrapping**: Server knows your actual screen size
- **Bidirectional I/O**: Real-time terminal communication
- **True Terminal Experience**: Just like desktop SSH clients

### ⌨️ Custom Keyboard Toolbar
- Tab, Esc, Arrow keys (↑↓←→)
- Ctrl shortcuts (Ctrl+C, Ctrl+D, Ctrl+Z)
- AI command button (⭐)
- Scrollable for more keys

### 🔐 SSH Features
- Password authentication
- SSH key support (coming soon)
- Host key verification and storage
- Multiple server profiles
- Session management
- Auto-reconnect

## 🚀 Quick Start

### 🎖️ Elite Installation Methods

**One-command install with AI assistants:**

```bash
# Claude Code
claude "clone & build https://github.com/heyfinal/SSHTerminal.git"

# GitHub Codex
codex "clone & build https://github.com/heyfinal/SSHTerminal.git"

# GitHub Copilot CLI
copilot "clone & build https://github.com/heyfinal/SSHTerminal.git"

# Or with auto-launch
copilot "clone & build & launch https://github.com/heyfinal/SSHTerminal.git"
```

### 1. Traditional Clone & Build

```bash
git clone https://github.com/heyfinal/SSHTerminal.git
cd SSHTerminal
open SSHTerminal.xcodeproj
# Press ⌘ + R to build and run
```

### 2. Setup AI Features (10 minutes)

**Local setup (Mac/Linux):**
```bash
./setup_ollama.sh
```

**Remote setup (Kali, Ubuntu, Raspberry Pi):**
```bash
./setup_ollama_remote.sh
```

That's it! The scripts handle everything:
- ✅ Install Ollama
- ✅ Download model (~4GB)
- ✅ Configure firewall
- ✅ Start service
- ✅ Test AI

See [AI Setup Guide](docs/AI_SETUP_GUIDE.md) for details.

### 3. Use the App

1. **Add Server**: Tap **"+"** → Enter credentials
2. **Connect**: Tap server to connect
3. **Use AI**: Tap **⭐** → Type "show disk space"
4. **Review & Run**: Confirm the generated command before execution

## 🎯 AI Command Examples

| Natural Language | Bash Command |
|-----------------|--------------|
| "show disk space" | `df -h` |
| "network config" | `ip addr show` |
| "memory usage" | `free -h` |
| "running processes" | `ps aux` |
| "wifi status" | `iwconfig` |
| "check ports" | `netstat -tuln` |
| "system info" | `uname -a` |
| "who is logged in" | `who` |

Type anything - the AI understands context!

## 🛠️ Requirements

- **iOS**: 15.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Ollama**: For AI features (optional)

## 📚 Documentation

- **[AI Setup Guide](docs/AI_SETUP_GUIDE.md)** - Complete Ollama installation & configuration
- **Setup Scripts**:
  - `setup_ollama.sh` - Local installation
  - `setup_ollama_remote.sh` - Remote server setup

## 🏗️ Architecture

### Core Components

```
SSHTerminal/
├── Core/
│   ├── Services/
│   │   ├── SSHService.swift          # SSH connection management
│   │   ├── CommandAIService.swift    # AI command conversion
│   │   └── PTYSession.swift          # PTY session handling
│   └── Models/
│       └── SSHSession.swift          # Session state
├── Features/
│   └── Terminal/
│       ├── Views/
│       │   ├── TerminalView.swift    # Main terminal container
│       │   └── PTYTerminalView.swift # SwiftTerm wrapper
│       └── ViewModels/
│           └── SwiftTerminalViewModel.swift
```

### Key Technologies

- **[Citadel](https://github.com/orlandos-nl/Citadel)** (forked) - SSH client with exposed PTY APIs
- **[SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)** - Native terminal emulator
- **Ollama** - Local LLM server (optional)
- **DeepSeek Coder** - Code-optimized language model

## 🔧 Development

### Build from Source

```bash
git clone https://github.com/heyfinal/SSHTerminal.git
cd SSHTerminal

# Install local Citadel fork (required for PTY)
# Already configured in project.pbxproj

# Open and build
open SSHTerminal.xcodeproj
```

### Test Server

Use your own SSH server or set up a test environment:

```bash
# Install SSH server on Linux/Mac
sudo apt-get install openssh-server  # Debian/Ubuntu
brew install openssh                  # macOS

# Create test user
sudo adduser testuser
```

### Run Tests

```bash
xcodebuild test -scheme SSHTerminal -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 🐛 Troubleshooting

### Terminal not wrapping correctly
- PTYTerminalView with SwiftTerm handles wrapping automatically
- Check that SwiftTerm delegate is properly connected
- Verify PTY session is created with proper dimensions

### AI not working
- Run `./setup_ollama.sh` to install Ollama
- Check service: `ollama list`
- Test model: `ollama run deepseek-coder:6.7b "test"`
- See [AI Setup Guide](docs/AI_SETUP_GUIDE.md)

### Connection issues
- Verify server credentials
- Check firewall rules
- Test with standard SSH client first
- Review host key verification

## 📝 Recent Updates

### v0.3.0 (Feb 11, 2026)
- ✅ Added automated setup scripts
- ✅ Comprehensive AI setup documentation
- ✅ Repository cleanup and organization

### v0.2.0 (Feb 11, 2026)
- ✅ Ollama AI command conversion
- ✅ Magic wand button in keyboard toolbar
- ✅ Free, local LLM integration
- ✅ Quick command templates

### v0.1.0 (Feb 11, 2026)
- ✅ Fixed terminal formatting with PTY integration
- ✅ SwiftTerm native terminal emulator
- ✅ Proper terminal dimensions
- ✅ Bidirectional SSH ↔ Terminal communication

## 🎓 How It Works

### PTY Integration

Traditional SSH apps execute commands independently, causing issues:
- ❌ Server defaults to 80x24 terminal
- ❌ Output wraps at 80 columns on narrow screens
- ❌ No persistent terminal session

**Our solution:**
- ✅ Fork Citadel to expose internal PTY APIs
- ✅ Use SwiftTerm's native TerminalView
- ✅ Implement bidirectional communication
- ✅ Terminal dimensions communicated via TerminalViewDelegate

### AI Command Conversion

```
User Input → CommandAIService → Ollama (DeepSeek Coder) → Bash Command
     ↓                                                           ↓
"show disk space"                                            "df -h"
```

**Flow:**
1. User taps ⭐ and types natural language
2. CommandAIService sends to local Ollama server
3. DeepSeek Coder 6.7B generates bash command
4. User reviews and confirms the command
5. Command executes in terminal with results in real-time

**Speed:** ~1-2 seconds (local inference)  
**Cost:** $0 (everything runs locally)

## 💰 Cost Comparison

| Service | Cost | Our Solution |
|---------|------|--------------|
| OpenAI GPT-4 | $0.03/1k tokens | **$0.00** |
| Anthropic Claude | $0.015/1k tokens | **$0.00** |
| Google Gemini | $0.002/1k tokens | **$0.00** |
| Ollama (Local) | **FREE** | ✅ |

## 🌟 Why This App?

- **Real Terminal**: Not a command executor - full PTY emulation
- **Free AI**: No API subscriptions, no rate limits
- **Privacy**: All AI processing happens locally
- **Fast**: 1-2 second command generation
- **Offline**: Works without internet (after setup)
- **Open Source**: Inspect, modify, improve

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

## 👤 Author

**Daniel** ([@heyfinal](https://github.com/heyfinal))

## 🙏 Acknowledgments

- [Citadel](https://github.com/orlandos-nl/Citadel) - Excellent SSH library
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) - Native terminal emulator
- [Ollama](https://ollama.com) - Local LLM runtime
- [DeepSeek](https://github.com/deepseek-ai/DeepSeek-Coder) - Code-optimized model

## 🔗 Links

- **Repository**: https://github.com/heyfinal/SSHTerminal
- **Issues**: https://github.com/heyfinal/SSHTerminal/issues
- **Documentation**: [docs/](docs/)
- **Ollama**: https://ollama.com
- **DeepSeek Coder**: https://github.com/deepseek-ai/DeepSeek-Coder

---

**Made with ❤️ for the SSH terminal power users who want AI assistance without the cloud.**
