//
//  AppConfig.swift
//  SSHTerminal
//
//  Centralized configuration for the app
//

import Foundation

/// Centralized configuration for the SSHTerminal app
enum AppConfig {

    // MARK: - App Identity

    /// App bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.daniel.sshterminal"
    }

    /// App version string
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// App build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - SSH Configuration

    enum SSH {
        /// Default SSH port
        static let defaultPort = 22

        /// Connection timeout in seconds
        static let connectionTimeout: TimeInterval = 30

        /// Command execution timeout in seconds
        static let commandTimeout: TimeInterval = 60

        /// Maximum reconnection attempts
        static let maxReconnectAttempts = 3

        /// Delay between reconnection attempts in seconds
        static let reconnectDelay: TimeInterval = 2
    }

    // MARK: - AI Configuration

    enum AI {
        /// OpenAI API endpoint
        static let apiEndpoint = "https://api.openai.com/v1/chat/completions"

        /// Maximum requests per minute (local rate limit)
        static let maxRequestsPerMinute = 20

        /// Rate limit window in seconds
        static let rateLimitWindow: TimeInterval = 60

        /// Request timeout in seconds
        static let requestTimeout: TimeInterval = 30

        /// Default model to use
        static let defaultModel = "gpt-4o-mini"

        /// Maximum context length to send
        static let maxContextLength = 4000

        /// Maximum tokens for command suggestions
        static let suggestionMaxTokens = 200

        /// Maximum tokens for error explanations
        static let errorExplanationMaxTokens = 300

        /// Maximum tokens for chat responses
        static let chatMaxTokens = 500

        /// Temperature for deterministic responses (commands)
        static let lowTemperature = 0.2

        /// Temperature for creative responses (chat)
        static let highTemperature = 0.7
    }

    // MARK: - Storage Keys

    enum StorageKeys {
        /// UserDefaults key for saved servers
        static let savedServers = "saved_servers"

        /// UserDefaults key for SSH known hosts
        static let sshKnownHosts = "ssh_known_hosts"

        /// UserDefaults key for SSH key metadata
        static let sshKeysMetadata = "ssh_keys_metadata"

        /// UserDefaults key for AI model selection
        static let aiSelectedModel = "ai_selected_model"

        /// UserDefaults key for total AI tokens used
        static let aiTotalTokens = "ai_total_tokens"

        /// UserDefaults key for estimated AI cost
        static let aiEstimatedCost = "ai_estimated_cost"

        /// UserDefaults key for command history
        static let commandHistory = "command_history"

        /// UserDefaults key for terminal settings
        static let terminalSettings = "terminal_settings"

        /// UserDefaults key for onboarding completed
        static let onboardingCompleted = "onboarding_completed"

        /// UserDefaults key for app appearance
        static let appearance = "app_appearance"

        /// UserDefaults key for snippets
        static let snippets = "saved_snippets"

        /// UserDefaults key for session recordings
        static let sessionRecordings = "session_recordings"
    }

    // MARK: - Keychain Keys

    enum KeychainKeys {
        /// Service identifier for general passwords
        static var service: String { bundleIdentifier }

        /// Service identifier for SSH keys
        static let sshKeys = "SSHTerminal.SSHKeys"

        /// Service identifier for SSH key passphrases
        static let sshKeyPassphrases = "SSHTerminal.SSHKeyPassphrases"

        /// Account key for OpenAI API key
        static let openAIKey = "openai_api_key"
    }

    // MARK: - Terminal Configuration

    enum Terminal {
        /// Maximum lines to keep in history
        static let maxHistoryLines = 10_000

        /// Maximum output buffer size in characters
        static let maxOutputBufferSize = 500_000

        /// Default font size
        static let defaultFontSize: CGFloat = 14

        /// Minimum font size
        static let minFontSize: CGFloat = 10

        /// Maximum font size
        static let maxFontSize: CGFloat = 24

        /// Default font family
        static let defaultFontFamily = "Menlo"

        /// Command history limit
        static let commandHistoryLimit = 500
    }

    // MARK: - Session Recording

    enum Recording {
        /// Maximum recording duration in seconds (1 hour)
        static let maxDuration: TimeInterval = 3600

        /// Maximum recordings to keep
        static let maxRecordings = 50

        /// Auto-delete recordings older than (30 days)
        static let autoDeleteAfterDays = 30
    }

    // MARK: - Security

    enum Security {
        /// Minimum password length for SSH keys
        static let minKeyPassphraseLength = 8

        /// Biometric authentication timeout in seconds
        static let biometricTimeout: TimeInterval = 300

        /// Auto-lock timeout in seconds (5 minutes)
        static let autoLockTimeout: TimeInterval = 300

        /// Maximum failed authentication attempts
        static let maxFailedAttempts = 5
    }

    // MARK: - Network

    enum Network {
        /// Maximum concurrent connections
        static let maxConcurrentConnections = 10

        /// Keep-alive interval in seconds
        static let keepAliveInterval: TimeInterval = 60

        /// DNS resolution timeout in seconds
        static let dnsTimeout: TimeInterval = 10
    }

    // MARK: - UI Constants

    enum UI {
        /// Animation duration for standard animations
        static let standardAnimationDuration: TimeInterval = 0.3

        /// Animation duration for quick animations
        static let quickAnimationDuration: TimeInterval = 0.15

        /// Debounce delay for search input
        static let searchDebounceDelay: TimeInterval = 0.3

        /// Haptic feedback enabled by default
        static let hapticFeedbackDefault = true
    }
}

// MARK: - Environment-based Configuration

extension AppConfig {

    /// Whether the app is running in debug mode
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Whether to enable verbose logging
    static var verboseLogging: Bool {
        isDebug
    }

    /// Whether to accept any host key (DANGEROUS - only for development)
    static var acceptAnyHostKey: Bool {
        #if DEBUG
        // Only allow in debug builds, and default to false
        return ProcessInfo.processInfo.environment["ACCEPT_ANY_HOST_KEY"] == "1"
        #else
        return false
        #endif
    }
}
