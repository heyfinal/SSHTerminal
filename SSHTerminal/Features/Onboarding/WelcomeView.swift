//
//  WelcomeView.swift
//  SSHTerminal
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    WelcomePageView(
                        icon: "lock.shield.fill",
                        title: "Welcome to SSH Terminal",
                        subtitle: "Professional SSH client for iOS",
                        description: "Connect securely to any server, anywhere. Your complete terminal solution."
                    )
                    .tag(0)
                    
                    FeaturePageView(
                        icon: "network",
                        title: "Connect Anywhere",
                        description: "SSH to any server with full terminal emulation. Password, key-based, and 2FA authentication supported."
                    )
                    .tag(1)
                    
                    FeaturePageView(
                        icon: "brain.head.profile",
                        title: "AI Powered",
                        description: "Smart command suggestions and error help. Let AI assist your workflow with intelligent recommendations."
                    )
                    .tag(2)
                    
                    FeaturePageView(
                        icon: "lock.shield",
                        title: "Bank-Level Security",
                        description: "SSH keys stored in Keychain. Face ID protection. All connections encrypted end-to-end."
                    )
                    .tag(3)
                    
                    FeaturePageView(
                        icon: "star.fill",
                        title: "Pro Features",
                        description: "SFTP file transfers, port forwarding, snippet library, and session management."
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < 4 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onboardingManager.completeOnboarding()
                    }
                }) {
                    Text(currentPage < 4 ? "Continue" : "Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "00f2fe"), Color(hex: "4facfe")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                if currentPage < 4 {
                    Button("Skip") {
                        onboardingManager.completeOnboarding()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct WelcomePageView: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 100, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "00f2fe"), Color(hex: "4facfe")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "4facfe"))
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
    }
}

struct FeaturePageView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(hex: "00f2fe").opacity(0.1))
                    .frame(width: 180, height: 180)
                
                Image(systemName: icon)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "00f2fe"), Color(hex: "4facfe")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
}
