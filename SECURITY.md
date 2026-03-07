# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | ✅ Yes             |
| < 1.0   | ⚠️ Beta            |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

### 🔒 Private Disclosure (Preferred)

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please report via:
- **Email:** Create an issue with title "SECURITY: [Brief Description]" and mark it as security-related
- **GitHub Security Advisory:** Use the [Security tab](https://github.com/heyfinal/SSHTerminal/security/advisories/new)

### What to Include

Please provide:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)
- Your contact information

### Response Timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Depends on severity
  - Critical: 1-7 days
  - High: 7-14 days
  - Medium: 14-30 days
  - Low: 30-90 days

## Security Best Practices

### For Users

1. **Keep Updated:** Always use the latest version
2. **SSH Keys:** Use key-based authentication when possible
3. **Server Access:** Only connect to trusted servers
4. **Network:** Use secure networks, avoid public WiFi for sensitive operations
5. **Ollama Setup:** Keep your local Ollama instance updated

### For Contributors

1. **No Hardcoded Secrets:** Never commit API keys, passwords, or tokens
2. **Input Validation:** Always validate user input
3. **Secure Storage:** Use Keychain for sensitive data
4. **Dependencies:** Keep dependencies updated
5. **Code Review:** All security-related changes require review

## Known Security Considerations

### SSH Connections
- ✅ Host key verification implemented
- ✅ Encrypted communication
- ⚠️ Password authentication (use keys when possible)
- 🔄 SSH key support coming soon

### AI Features
- ✅ Local processing (no data sent to cloud)
- ✅ Ollama runs on local network
- ✅ No API keys stored
- ✅ Generated commands require user confirmation before execution
- ⚠️ Always review AI-generated commands for correctness

### Data Storage
- ✅ Passwords stored in iOS Keychain
- ✅ Host keys securely stored
- ✅ No analytics or tracking
- ✅ No data collection

## Security Updates

Security updates will be:
- Released as soon as possible
- Documented in release notes
- Announced in README
- Tagged with `security` label

## Bug Bounty

Currently, we do not offer a bug bounty program. However, we deeply appreciate security researchers who responsibly disclose vulnerabilities.

**Recognition:**
- Your name in the security acknowledgments (if desired)
- Credit in release notes
- Our sincere gratitude 🙏

## Security Checklist

Before each release, we verify:

- [ ] No hardcoded credentials
- [ ] Dependencies updated
- [ ] Security issues resolved
- [ ] Code reviewed
- [ ] Tests passing
- [ ] SwiftLint checks passing

## Contact

For security concerns: Open a security advisory on GitHub

---

**Thank you for helping keep SSHTerminal secure!** 🔒
