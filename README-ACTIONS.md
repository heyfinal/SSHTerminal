# GitHub Actions Workflows

This repository uses GitHub Actions for automated testing, code quality checks, and releases.

## 🤖 Available Workflows

### 1. **iOS Build & Test** (`ios-build-test.yml`)
Runs on: Push to main, Pull Requests, Manual trigger

**Jobs:**
- 🏗️ **Build & Test**: Compiles app and runs unit tests
- 🎨 **Code Quality**: SwiftLint checks and code statistics  
- 🔒 **Security Scan**: Checks for exposed secrets and hardcoded credentials
- 📦 **Archive**: Creates release archive (main branch only)

**Triggers:**
```bash
# Automatically runs on push/PR
git push origin main

# Manual trigger
gh workflow run ios-build-test.yml
```

### 2. **Automated Code Review** (`code-review.yml`)
Runs on: Pull Requests

**Checks:**
- 📊 PR statistics (lines changed, files modified)
- 🎨 Swift style guide compliance
- 🔒 Security review for secrets
- ⚠️ Force unwrapping detection
- 📝 TODO/FIXME tracking

### 3. **Dependency Updates** (`dependency-update.yml`)
Runs on: Weekly schedule (Mondays), Manual trigger

**Jobs:**
- 📦 Check for Swift package updates
- 🔍 Scan for outdated dependencies
- 📊 Generate dependency report

### 4. **Release Build** (`release.yml`)
Runs on: Version tags (`v*`)

**Jobs:**
- 🔖 Extract version from tag
- 🏗️ Build release configuration
- 📝 Generate release notes from commits
- 📤 Create GitHub release (draft)

**Usage:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

## 📊 Workflow Status Badges

Add to your README:

```markdown
![iOS Build](https://github.com/heyfinal/SSHTerminal/actions/workflows/ios-build-test.yml/badge.svg)
![Code Quality](https://github.com/heyfinal/SSHTerminal/actions/workflows/code-review.yml/badge.svg)
```

## 🔧 Configuration

### Requirements
- **macOS Runner**: `macos-14` (Xcode 15+)
- **iOS Target**: iPhone 16 Pro simulator
- **Swift**: 5.9+

### Environment Variables
Edit in workflow files:
```yaml
env:
  SCHEME: SSHTerminal
  PLATFORM: iOS Simulator
  DEVICE: iPhone 16 Pro
  IOS_VERSION: latest
```

## 🐛 Debugging Failed Workflows

### Build Failures
1. Check **Build Logs** artifact
2. Look for compilation errors
3. Verify dependencies resolved

### Test Failures
1. Download **Test Results** artifact
2. Check `.xcresult` bundle
3. Review test logs

### Manual Run
```bash
# Trigger workflow manually
gh workflow run ios-build-test.yml

# View recent runs
gh run list

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

## 📦 Artifacts

Workflows upload these artifacts:

| Artifact | Retention | Contents |
|----------|-----------|----------|
| `build-logs` | 7 days | build.log, test.log |
| `test-results` | 7 days | .xcresult bundles |
| `app-archive` | 30 days | .xcarchive (main only) |

## 🔒 Security

### Secret Scanning
The security workflow checks for:
- API keys
- Hardcoded passwords
- Private IP addresses
- Exposed tokens

### Recommendations
- Never commit secrets
- Use Xcode configuration files (not tracked)
- Store sensitive data in Keychain
- Use environment variables

## 💡 Tips

### Speed Up Builds
1. Use dependency caching (coming soon)
2. Run only changed tests
3. Parallel testing

### Custom Checks
Add your own steps:
```yaml
- name: Custom Check
  run: |
    # Your script here
```

### Notifications
Enable in repository settings:
- Settings → Notifications
- Choose Slack/Email/Discord

## 📚 Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Xcode Cloud vs Actions](https://developer.apple.com/xcode-cloud/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/)

## 🚀 Future Enhancements

- [ ] Code coverage reports
- [ ] Performance benchmarks
- [ ] UI screenshot tests
- [ ] Automated App Store upload
- [ ] Dependency caching
- [ ] Matrix testing (multiple iOS versions)
