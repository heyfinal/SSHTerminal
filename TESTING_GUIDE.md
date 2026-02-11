# SSH Terminal - Beta Testing Guide

## Welcome Beta Tester! 🎉

Thank you for helping us test SSH Terminal. This guide will help you get the most out of the beta program.

## What We're Testing

### Core Features
- ✅ SSH connection management
- ✅ Terminal emulation
- ✅ SSH key authentication
- ✅ Password authentication
- ✅ Server profile management

### New Beta Features
- 🆕 AI-powered command suggestions
- 🆕 SFTP file transfers
- 🆕 Port forwarding
- 🆕 Snippet library
- 🆕 Session management
- 🆕 Multi-server support

## Getting Started

### 1. Install TestFlight
1. Download TestFlight from the App Store
2. Open the beta invitation link
3. Install SSH Terminal Beta

### 2. First Launch
You'll see a welcome tour highlighting key features. Feel free to skip if you want to dive right in.

### 3. Add Your First Server
1. Tap "+" to add a server
2. Enter connection details:
   - Hostname or IP
   - Port (default: 22)
   - Username
   - Authentication method (password or key)

### 4. Connect
Tap the server to connect. You'll see a full terminal interface.

## What to Test

### High Priority 🔴
1. **Connection Stability**
   - Do connections work reliably?
   - Does the app handle network changes?
   - Can you reconnect after backgrounding?

2. **Terminal Functionality**
   - Does text input work correctly?
   - Are special keys (Ctrl, Tab, etc.) working?
   - Is the terminal responsive?

3. **Authentication**
   - Password authentication
   - SSH key authentication
   - Multi-factor authentication

### Medium Priority 🟡
1. **AI Features** (if enabled)
   - Command suggestions quality
   - Error explanations helpfulness
   - Performance impact

2. **UI/UX**
   - Is the interface intuitive?
   - Are animations smooth?
   - Does dark mode work well?

3. **Settings**
   - Do preferences save correctly?
   - Does appearance customization work?
   - Is biometric auth working?

### Low Priority 🟢
1. **Advanced Features**
   - SFTP file transfers
   - Port forwarding setup
   - Snippet management

2. **Edge Cases**
   - Very long terminal output
   - Special characters
   - Multiple simultaneous connections

## Known Issues

### Current Limitations
- ⚠️ SFTP browser is read-only in beta 1
- ⚠️ Port forwarding requires manual configuration
- ⚠️ AI features require API key setup

### Under Investigation
- 🔍 Occasional keyboard dismissal on iPad
- 🔍 Terminal scrolling performance with large buffers
- 🔍 Connection timeout on some cellular networks

## How to Report Issues

### Using TestFlight
1. Take a screenshot of the issue
2. In TestFlight, tap "Send Beta Feedback"
3. Describe what happened
4. Attach screenshot if relevant

### Important Information to Include
- Device model (iPhone 14 Pro, iPad Pro 12.9", etc.)
- iOS version
- Steps to reproduce
- Expected vs actual behavior
- Server type (if relevant)

### Crash Reports
Crashes are automatically reported if you've enabled it in TestFlight settings.

## Feature Requests

We love hearing your ideas! Please submit feature requests through:
- TestFlight feedback
- Email: beta@sshterminal.app
- Twitter: @sshterminal

## Testing Scenarios

### Basic Workflow
1. Add server → Connect → Run commands → Disconnect
2. Try with different auth methods
3. Test connection recovery after network change

### Advanced Workflow
1. Set up multiple servers
2. Switch between connections
3. Use AI suggestions
4. Save frequently-used commands as snippets

### Stress Testing
1. Open very long log files (`less /var/log/syslog`)
2. Run commands with lots of output (`find / -name "*"`)
3. Keep connection open for extended period
4. Background and foreground the app repeatedly

## Privacy & Security

### What We Collect
- Anonymous crash reports (optional)
- Feature usage analytics (optional)
- No passwords or SSH keys are transmitted

### Your Data
- All credentials stored in iOS Keychain
- No data leaves your device except SSH connections
- AI features only send commands if you opt-in

## FAQ

### Q: Can I use this with production servers?
A: Yes! The SSH implementation is production-ready. However, always keep backups and test carefully.

### Q: Why do AI features require API keys?
A: We don't have centralized servers. You connect directly to OpenAI/Claude APIs. This keeps your data private.

### Q: Does it work on iPad?
A: Yes! Fully optimized for iPad with keyboard shortcuts.

### Q: Can I use external keyboards?
A: Absolutely! All keyboard shortcuts work with external keyboards.

### Q: What about Bluetooth keyboards?
A: Full support for Bluetooth keyboards including special keys.

## Support

### Getting Help
- Email: support@sshterminal.app
- Twitter: @sshterminal
- FAQ: https://sshterminal.app/faq

### Beta Community
Join other beta testers:
- Discord: [link]
- TestFlight comments
- Twitter hashtag: #SSHTerminalBeta

## Release Schedule

### Beta 1 (Current)
- Core SSH functionality
- Basic UI/UX
- Settings and preferences

### Beta 2 (Planned)
- Enhanced SFTP browser
- Improved AI features
- Performance optimizations

### Beta 3 (Planned)
- Port forwarding UI
- Snippet sharing
- iPad multitasking improvements

### Public Release
- Targeting Q2 2025
- Will include all beta features plus:
  - In-app tutorials
  - Cloud sync
  - Pro features

## Thank You!

Your feedback is invaluable. Every bug report and suggestion helps make SSH Terminal better for everyone.

Happy testing! 🚀

---

**Beta Program Version:** 1.0 (Build 1)  
**Last Updated:** February 2025  
**Next Update:** Check TestFlight for new builds
