//
//  LicensesView.swift
//  SSHTerminal
//

import SwiftUI

struct LicensesView: View {
    var body: some View {
        List {
            LicenseSection(
                name: "SwiftTerm",
                author: "Miguel de Icaza",
                license: "MIT License",
                url: "https://github.com/migueldeicaza/SwiftTerm"
            )
            
            LicenseSection(
                name: "Citadel",
                author: "Joannis Orlandos",
                license: "MIT License",
                url: "https://github.com/Joannis/Citadel"
            )
            
            LicenseSection(
                name: "OpenSSL",
                author: "OpenSSL Project",
                license: "Apache License 2.0",
                url: "https://www.openssl.org"
            )
            
            LicenseSection(
                name: "Swift Crypto",
                author: "Apple Inc.",
                license: "Apache License 2.0",
                url: "https://github.com/apple/swift-crypto"
            )
        }
        .navigationTitle("Open Source Licenses")
    }
}

struct LicenseSection: View {
    let name: String
    let author: String
    let license: String
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            
            Text("by \(author)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(license)
                .font(.caption)
                .foregroundColor(.blue)
            
            Link("View on GitHub", destination: URL(string: url)!)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        LicensesView()
    }
}
