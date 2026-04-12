import SwiftUI

struct AutocompleteBarView: View {
    @ObservedObject var autocomplete: BashAutocompleteService
    let onInsert: ([UInt8]) -> Void

    var body: some View {
        if autocomplete.suggestions.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(autocomplete.suggestions) { suggestion in
                        SuggestionChip(suggestion: suggestion) {
                            let bytes = autocomplete.insertionBytes(for: suggestion)
                            onInsert(bytes)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .frame(height: 38)
            .background(Color.black.opacity(0.9))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.green.opacity(0.3)),
                alignment: .top
            )
        }
    }
}

private struct SuggestionChip: View {
    let suggestion: AutocompleteSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                kindIcon
                    .font(.system(size: 10))
                    .foregroundColor(kindColor.opacity(0.8))

                Text(suggestion.displayText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(kindColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(kindColor.opacity(0.4), lineWidth: 0.5)
            )
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }

    private var kindIcon: Image {
        switch suggestion.kind {
        case .command:  return Image(systemName: "terminal")
        case .path:     return Image(systemName: "folder")
        case .history:  return Image(systemName: "clock")
        case .argument: return Image(systemName: "chevron.right")
        }
    }

    private var kindColor: Color {
        switch suggestion.kind {
        case .command:  return .green
        case .path:     return .cyan
        case .history:  return .yellow
        case .argument: return .orange
        }
    }
}
