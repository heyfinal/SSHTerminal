# Contributing to SSHTerminal

First off, thanks for taking the time to contribute! 🎉

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected vs. actual behavior**
- **Screenshots** (if applicable)
- **Environment details** (iOS version, device model)

**Bug Report Template:**
```markdown
**Describe the bug**
A clear description of the bug.

**To Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
Add screenshots if applicable.

**Environment:**
- Device: [e.g., iPhone 16 Pro]
- iOS: [e.g., 17.2]
- App Version: [e.g., 1.0.0]
```

### 💡 Suggesting Features

Feature requests are welcome! Please include:

- **Use case**: Why is this feature needed?
- **Proposed solution**: How should it work?
- **Alternatives**: What other solutions did you consider?

### 🔧 Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Make your changes** with clear, focused commits
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Follow the code style** (SwiftLint will check)
6. **Submit the PR** with a clear description

**PR Checklist:**
- [ ] Code compiles without warnings
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] Code follows Swift style guide

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/SSHTerminal.git
cd SSHTerminal

# Open in Xcode
open SSHTerminal.xcodeproj

# Build and run (⌘ + R)
```

## Code Style

- Use **SwiftLint** for style enforcement
- Follow **Swift API Design Guidelines**
- Write **clear, self-documenting code**
- Add **comments for complex logic only**
- Use **meaningful variable names**

### Swift Style Examples

```swift
// ✅ Good
func convertToCommand(_ naturalLanguage: String) async throws -> String {
    let response = try await aiService.generate(prompt: naturalLanguage)
    return response.command
}

// ❌ Bad
func conv(nl: String) async throws -> String {
    let r = try await ai.gen(nl)
    return r.cmd
}
```

## Project Structure

```
SSHTerminal/
├── App/                    # App lifecycle
├── Core/
│   ├── Models/            # Data models
│   └── Services/          # Business logic
├── Features/
│   ├── Terminal/          # Terminal UI & logic
│   └── Settings/          # Settings screens
└── Resources/             # Assets, configs
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add voice input for commands
fix: resolve PTY dimension bug on iPad
docs: update AI setup guide
style: format code with SwiftLint
refactor: simplify command service
test: add unit tests for AI service
chore: update dependencies
```

## Testing

```bash
# Run tests
xcodebuild test -scheme SSHTerminal \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run SwiftLint
swiftlint lint
```

## Areas for Contribution

### 🔥 High Priority
- [ ] Voice input for commands
- [ ] AI command explanation (reverse)
- [ ] SSH key authentication
- [ ] Session persistence
- [ ] Multi-tab support

### 🎨 UI/UX Improvements
- [ ] Custom terminal themes
- [ ] Font size adjustment
- [ ] Dark mode refinements
- [ ] iPad split view

### 🤖 AI Features
- [ ] Command history learning
- [ ] Error debugging suggestions
- [ ] Smart auto-completion
- [ ] Alternative command suggestions

### 📚 Documentation
- [ ] Video tutorials
- [ ] More code examples
- [ ] API documentation
- [ ] Troubleshooting guide

### 🧪 Testing
- [ ] Unit tests for services
- [ ] UI tests for flows
- [ ] Integration tests
- [ ] Performance tests

## Community

- **Questions?** Open a [Discussion](https://github.com/heyfinal/SSHTerminal/discussions)
- **Bug?** Open an [Issue](https://github.com/heyfinal/SSHTerminal/issues)
- **Feature idea?** Start a [Discussion](https://github.com/heyfinal/SSHTerminal/discussions)
- **Want to contribute?** Check [Issues labeled "good first issue"](https://github.com/heyfinal/SSHTerminal/labels/good%20first%20issue)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

All contributors will be acknowledged in the README and releases.

---

**Thank you for contributing to SSHTerminal!** 🚀
