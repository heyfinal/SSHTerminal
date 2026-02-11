# SSHTerminal Development History

## Project Overview
iOS SSH Terminal app with PTY integration, SwiftTerm native terminal emulator, and AI-powered command conversion.

## Major Milestones

### Phase 1-5: Initial Development (Feb 10, 2026)
- Project structure and SSH connectivity
- Terminal UI with EnhancedTerminalView
- AI assistant integration (OpenAI)
- Command suggestions and error handling
- Initial beta release

### PTY Integration (Feb 11, 2026)
**Problem:** Terminal output wrapping at 80 columns regardless of screen width
**Root Cause:** Using `executeCommand()` instead of persistent PTY sessions
**Solution:** 
- Forked Citadel library to expose internal PTY APIs
- Created PTYTerminalView using SwiftTerm's native TerminalView
- Implemented bidirectional communication (SSH ↔ Terminal)
- Terminal dimensions properly communicated via TerminalViewDelegate

**Commit:** `b3979ea` - "Fix terminal formatting: Implement proper PTY integration with SwiftTerm"

### Ollama AI Integration (Feb 11, 2026)
**Feature:** Natural language → bash command conversion
**Implementation:**
- CommandAIService using local Ollama server (Kali: ***REMOVED***:11434)
- Model: deepseek-coder:6.7b (optimized for code)
- Magic wand button (⭐) in keyboard toolbar
- Quick templates for common commands
- 100% free, no API costs

**Commit:** `8c0a0b1` - "Add Ollama AI command conversion"

## Key Technical Decisions

1. **Local Citadel Fork**: Necessary to expose internal PTY APIs
   - Location: `~/Development/citadel-pty-fork`
   - Branch: `pty-public-api`

2. **Concurrency Model**: Changed from `complete` to `minimal` strict concurrency
   - Required for PTY integration with NIO types
   - Uses `@unchecked Sendable` with proper weak captures

3. **AI Strategy**: Local Ollama instead of cloud APIs
   - Free, fast (~1-2 seconds)
   - No API keys or rate limits
   - Privacy-preserving

## Architecture

### Core Components
- **SSHService**: Connection management, PTY session creation
- **PTYTerminalView**: UIViewRepresentable wrapper for SwiftTerm
- **CommandAIService**: Natural language command conversion
- **TerminalViewModel**: Terminal state and I/O (legacy, kept for reference)

### Key Files
- `PTYTerminalView.swift` - SwiftTerm integration with TerminalViewDelegate
- `CommandAIService.swift` - Ollama AI command conversion
- `SSHService.swift` - SSH client management
- `TerminalView.swift` - Main terminal container

## External Dependencies
- **Citadel** (forked): SSH client library
- **SwiftTerm**: Native terminal emulator
- **Ollama**: Local LLM server on Kali (***REMOVED***)

## Testing
- Kali server: `daniel@***REMOVED***` (password: ***REMOVED***)
- Ollama models: deepseek-coder:6.7b, dolphin-mistral:7b-v2.8, tinyllama:latest
- Simulator: iPhone 16 Pro (iOS 18.6)

## Known Issues
None currently - PTY formatting working, AI conversion operational.

## Future Enhancements
- [ ] SSH key authentication
- [ ] SFTP file transfer
- [ ] Session persistence
- [ ] Terminal themes
- [ ] Command history search
- [ ] Multi-session tabs
