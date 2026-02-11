//
//  LaunchScreenView.swift
//  SSHTerminal
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "4facfe").opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.5 : 1)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00f2fe"), Color(hex: "4facfe")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                }
                
                VStack(spacing: 8) {
                    Text("SSH Terminal")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showText ? 1 : 0)
                    
                    Text("Secure Remote Access")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showText ? 1 : 0)
                }
                .offset(y: showText ? 0 : 20)
                
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(hex: "00f2fe"))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .opacity(showText ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showText = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
