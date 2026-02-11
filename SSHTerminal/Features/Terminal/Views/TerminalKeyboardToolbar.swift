//
//  TerminalKeyboardToolbar.swift
//  SSHTerminal
//
//  Custom keyboard toolbar for terminal shortcuts
//

import SwiftUI

struct TerminalKeyboardToolbar: View {
    let onKey: (String) -> Void
    
    private let keys = [
        ("Tab", "\t"),
        ("Esc", "\u{1B}"),
        ("↑", "\u{1B}[A"),
        ("↓", "\u{1B}[B"),
        ("←", "\u{1B}[D"),
        ("→", "\u{1B}[C"),
        ("Ctrl+C", "\u{03}"),
        ("Ctrl+D", "\u{04}"),
        ("Ctrl+Z", "\u{1A}")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(keys, id: \.0) { key in
                    Button {
                        onKey(key.1)
                    } label: {
                        Text(key.0)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 44)
        .background(Color.black.opacity(0.95))
    }
}
