# SSH Terminal

A professional iOS SSH terminal app with AI assistance, built with SwiftUI and modern Swift concurrency.

## Features

### 🔐 Security
- SSH password authentication
- SSH public key authentication (RSA, ECDSA, Ed25519)
- Host key validation (TOFU pattern)
- Secure Keychain storage for credentials
- MITM attack detection

### 💻 Terminal
- Full-featured SSH client using Citadel
- Professional command prompt (user@host:dir$)
- Color-coded output (ANSI colors)
- Command history (up/down arrows)
- Blinking cursor
- Clear screen support
- Directory tracking

### 🤖 AI Features
- OpenAI GPT-4o / GPT-4o-mini integration
- Smart command suggestions
- Error explanations
- Natural language to command translation
- AI chat assistant
- Rate limiting (20 req/min)

### 📦 Advanced Features
- Multiple server profiles
- Session management
- Command snippets library (15 pre-loaded)
- Command history search
- Dark mode optimized UI
- Haptic feedback
- VoiceOver accessibility
- Dynamic Type support

## Tech Stack

- **Language**: Swift 6.0
- **Framework**: SwiftUI (iOS 17+)
- **SSH Library**: Citadel 0.11.1
- **Terminal**: SwiftTerm 1.6.0
- **Architecture**: MVVM + Clean Architecture
- **Concurrency**: Swift 6 strict concurrency

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/heyfinal/SSHTerminal.git
cd SSHTerminal
```

2. Open in Xcode:
```bash
open SSHTerminal.xcodeproj
```

3. Build and run (⌘R)

## Configuration

### AI Features (Optional)
To use AI features, add your OpenAI API key:
1. Open app Settings
2. Navigate to AI Settings
3. Enter your OpenAI API key

### SSH Keys (Optional)
To use SSH key authentication:
1. Go to server settings
2. Select "SSH Key" authentication
3. Import your private key from Files app

## Project Structure

```
SSHTerminal/
├── App/                    # App entry point
├── Core/                   # Models, Services, Repositories
│   ├── Models/            # Data models
│   ├── Services/          # Business logic
│   └── Repositories/      # Data persistence
├── Features/              # UI Features
│   ├── ServerList/        # Server management
│   ├── Terminal/          # Terminal interface
│   ├── AI/               # AI assistant
│   ├── Onboarding/       # First-run experience
│   └── Settings/         # App settings
└── Resources/            # Assets, Info.plist
```

## Security Notes

- Passwords stored securely in iOS Keychain
- SSH keys encrypted with Keychain
- Host keys validated on first connection
- No credentials stored in plain text
- MITM attack detection via host key fingerprinting

## Development

### Run Tests
```bash
xcodebuild test -project SSHTerminal.xcodeproj -scheme SSHTerminal
```

### Build for Release
```bash
xcodebuild archive -project SSHTerminal.xcodeproj -scheme SSHTerminal
```

## Roadmap

- [ ] Interactive PTY support (vim, htop, nano)
- [ ] SFTP file browser
- [ ] Port forwarding UI
- [ ] iCloud sync
- [ ] Widgets & Shortcuts
- [ ] Multiple sessions/tabs
- [ ] Session recording

## Credits

Built with:
- [Citadel](https://github.com/Joannis/Citadel) - SSH client for Swift
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) - Terminal emulator

## License

MIT License - See LICENSE file for details

## Author

Daniel Gillaspy (@heyfinal)

## Development Timeline

- **Phase 1**: Foundation (SwiftUI, MVVM) - Complete
- **Phase 2**: SSH Integration (Citadel) - Complete
- **Phase 3**: Terminal UI - Complete
- **Phase 4**: AI Integration - Complete
- **Phase 5**: Advanced Features - Complete
- **Phase 6**: Beta Polish - Complete
- **Security Audit**: Complete (2026-02-11)

Built autonomously with parallel AI agents in ~70 minutes + security hardening.

