# SSH Terminal - iOS Beta Program

<div align="center">

![SSH Terminal Icon](https://via.placeholder.com/150x150/0f3460/00f2fe?text=SSH)

**Professional SSH client for iPhone and iPad**

[![TestFlight](https://img.shields.io/badge/TestFlight-Beta-blue)](https://testflight.apple.com/join/sshterminal)
[![iOS](https://img.shields.io/badge/iOS-15.0+-black)](https://www.apple.com/ios)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[Join Beta](#join-beta) • [Features](#features) • [Screenshots](#screenshots) • [Support](#support)

</div>

---

## 🎯 What is SSH Terminal?

SSH Terminal is a **modern, professional SSH client** for iOS that brings the power of terminal access to your iPhone and iPad. Built with SwiftUI, it offers a native iOS experience while maintaining full compatibility with SSH servers worldwide.

### Why SSH Terminal?

- 🔒 **Bank-level security** - Keys stored in iOS Keychain, Face ID/Touch ID support
- 🧠 **AI-powered** - Smart command suggestions and error explanations (optional)
- 🎨 **Beautiful UI** - Native iOS design, dark mode, customizable themes
- ⚡ **Fast & responsive** - Optimized for iOS, smooth 60fps animations
- 🔌 **Full-featured** - SFTP, port forwarding, snippet library, multi-session
- 🔐 **Privacy-first** - No data collection, no tracking, no cloud (unless you enable iCloud sync)

---

## ✨ Features

### Core SSH
- ✅ Full terminal emulation (VT100/ANSI)
- ✅ Password & SSH key authentication
- ✅ Multi-factor authentication (2FA)
- ✅ Multiple simultaneous connections
- ✅ Session management & reconnection
- ✅ Clipboard integration

### Security
- 🔐 Keychain storage for credentials
- 👤 Face ID / Touch ID protection
- ⏱️ Auto-lock timeout
- 🙈 Screenshot protection
- 🔑 SSH key generation (RSA, ED25519)

### AI Assistant (Optional)
- 🤖 Command suggestions based on context
- 💡 Error explanations and fixes
- 📚 Learning from your workflow
- 🔌 OpenAI GPT-4 or Anthropic Claude
- 🏠 Local AI via Ollama (privacy-focused)

### Pro Features
- 📁 SFTP file browser & transfers
- 🔀 Port forwarding (local & remote)
- 📝 Snippet library for common commands
- ⚙️ Custom key bindings
- 🎨 Terminal themes (Solarized, Dracula, etc.)
- ☁️ iCloud sync (optional)

### UI/UX
- 🌙 Beautiful dark mode
- 📱 Optimized for iPhone & iPad
- ⌨️ External keyboard support
- 🎮 Haptic feedback
- ♿ Full accessibility support
- 🌍 Localization ready

---

## 📱 Requirements

- iOS 15.0 or later
- iPhone (6.1" or larger recommended)
- iPad (all models supported)
- iPadOS for full keyboard/multitasking support

---

## 🚀 Join Beta

### Step 1: Install TestFlight
Download TestFlight from the App Store if you haven't already.

### Step 2: Join the Beta
Click this link on your iOS device:

**[Join SSH Terminal Beta](https://testflight.apple.com/join/sshterminal)**

### Step 3: Install & Test
1. Open the TestFlight app
2. Accept the invitation
3. Install SSH Terminal
4. Start testing and provide feedback!

---

## 📸 Screenshots

<div align="center">

### Server List
*Manage multiple SSH connections*

### Terminal
*Full-featured terminal with color support*

### Settings
*Customize appearance, security, and behavior*

### AI Assistant
*Get smart suggestions as you type*

</div>

---

## 🧪 What We're Testing

### Beta 1 Focus (Current)
- ✅ Core SSH connectivity and stability
- ✅ Terminal emulation accuracy
- ✅ Authentication methods (password, keys, 2FA)
- ✅ UI/UX smoothness and intuitiveness
- ✅ Settings persistence

### Beta 2 Focus (Coming Soon)
- 🔄 Enhanced SFTP browser
- 🔄 Improved AI integration
- 🔄 Performance optimizations
- 🔄 iPad multitasking
- 🔄 Keyboard shortcuts

### Beta 3 Focus (Planned)
- 📅 Port forwarding UI
- 📅 Snippet sharing
- 📅 Cloud sync improvements
- 📅 Advanced terminal features

---

## 📖 Documentation

- **[Testing Guide](TESTING_GUIDE.md)** - Comprehensive guide for beta testers
- **[Beta Ready Report](BETA_READY_REPORT.md)** - Complete feature status
- **[Privacy Policy](SSHTerminal/Features/Legal/PrivacyPolicyView.swift)** - How we handle data
- **[Terms of Service](SSHTerminal/Features/Legal/TermsOfServiceView.swift)** - Legal terms

---

## 🐛 Reporting Issues

### Via TestFlight
1. Take a screenshot (if applicable)
2. Open TestFlight
3. Tap "Send Beta Feedback"
4. Describe the issue

### Via Email
Send detailed bug reports to: **beta@sshterminal.app**

### What to Include
- Device model (e.g., iPhone 14 Pro)
- iOS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/screen recordings

---

## 💡 Feature Requests

We love hearing your ideas! Submit feature requests through:
- TestFlight feedback
- Email: features@sshterminal.app
- Twitter: [@sshterminal](https://twitter.com/sshterminal)
- GitHub Issues: [github.com/sshterminal/ios](https://github.com/sshterminal/ios)

---

## 🤝 Community

### Join the Conversation
- **Discord:** [Join our server](#) (Coming soon)
- **Twitter:** [@sshterminal](https://twitter.com/sshterminal)
- **Reddit:** [r/sshterminal](#) (Coming soon)
- **Hashtag:** #SSHTerminalBeta

### Beta Testers Leaderboard
Top contributors will be:
- 🏆 Listed in app credits
- 🎁 Receive free Pro subscription
- 🎖️ Get exclusive beta tester badge

---

## 📅 Release Timeline

| Phase | Timeframe | Status |
|-------|-----------|--------|
| **Beta 1** | Week 1-2 | 🟢 In Progress |
| **Beta 2** | Week 3-4 | ⏳ Planned |
| **Beta 3** | Week 5-6 | ⏳ Planned |
| **Public Beta** | Week 7-8 | ⏳ Planned |
| **App Store** | Q2 2025 | 📅 Scheduled |

---

## ❓ FAQ

### Q: Is this free?
**A:** Beta is completely free. The released app will have a free tier with core features and an optional Pro subscription for advanced features.

### Q: Why does AI require API keys?
**A:** We don't run centralized servers for AI. You connect directly to OpenAI/Claude, keeping your data private and giving you control.

### Q: Does it work on iPad?
**A:** Yes! Fully optimized for iPad with keyboard shortcuts and multitasking.

### Q: Can I use external keyboards?
**A:** Absolutely! Full support for Bluetooth and USB keyboards, including special keys.

### Q: Is my data safe?
**A:** Yes! Credentials stored in iOS Keychain, connections are encrypted, and we collect no data without your explicit consent.

### Q: Can I sync across devices?
**A:** iCloud sync is optional and coming in Beta 2. Your data stays encrypted.

### Q: What about privacy?
**A:** We're privacy-first. No tracking, no ads, no data collection. Read our [Privacy Policy](SSHTerminal/Features/Legal/PrivacyPolicyView.swift).

---

## 🛠️ Built With

- **[SwiftUI](https://developer.apple.com/xcode/swiftui/)** - Modern UI framework
- **[SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)** - Terminal emulator
- **[Citadel](https://github.com/Joannis/Citadel)** - SSH library
- **[OpenSSL](https://www.openssl.org)** - Cryptography

---

## 👏 Credits

### Development
- **Lead Developer:** Daniel
- **UI/UX Design:** SSH Terminal Team

### Open Source
Special thanks to:
- Miguel de Icaza - SwiftTerm
- Joannis Orlandos - Citadel
- OpenSSL Project

---

## 📞 Support

### Get Help
- **Email:** support@sshterminal.app
- **Twitter:** [@sshterminal](https://twitter.com/sshterminal)
- **Website:** [sshterminal.app](https://sshterminal.app)

### Response Time
- Beta testers: < 24 hours
- Critical bugs: < 4 hours
- Feature requests: Weekly review

---

## 📄 License

SSH Terminal is proprietary software. Beta testing does not grant distribution rights.

Open source components used are licensed under their respective licenses (MIT, Apache 2.0).

---

## 🎉 Thank You!

Thank you for being part of the SSH Terminal beta program. Your feedback and testing help make this app better for everyone.

**Let's build something amazing together!** 🚀

---

<div align="center">

Made with ❤️ by the SSH Terminal Team

[Website](https://sshterminal.app) • [Twitter](https://twitter.com/sshterminal) • [GitHub](https://github.com/sshterminal/ios)

**© 2025 SSH Terminal. All rights reserved.**

</div>
