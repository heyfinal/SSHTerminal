//
//  AppIconGenerator.swift
//  SSHTerminal
//
//  App Icon Generator for SSH Terminal
//

import SwiftUI

struct AppIconDesign: View {
    var body: some View {
        ZStack {
            // Background gradient - dark terminal theme
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Terminal window
            VStack(spacing: 0) {
                // Terminal header
                HStack {
                    Circle().fill(Color.red).frame(width: 40, height: 40)
                    Circle().fill(Color.yellow).frame(width: 40, height: 40)
                    Circle().fill(Color.green).frame(width: 40, height: 40)
                    Spacer()
                }
                .padding(40)
                
                // Terminal content with SSH icon
                VStack(spacing: 20) {
                    // SSH Lock symbol
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 200, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00f2fe"), Color(hex: "4facfe")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Terminal prompt
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(Color(hex: "00f2fe"))
                        
                        Rectangle()
                            .fill(Color(hex: "00f2fe"))
                            .frame(width: 40, height: 60)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    AppIconDesign()
}
