//
//  AppearanceSettingsView.swift
//  SSHTerminal
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("terminalTheme") private var terminalTheme = "dark"
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("fontFamily") private var fontFamily = "Menlo"
    @AppStorage("colorScheme") private var colorScheme = "solarizedDark"
    
    var body: some View {
        List {
            Section("Theme") {
                Picker("Color Scheme", selection: $colorScheme) {
                    Text("Solarized Dark").tag("solarizedDark")
                    Text("Dracula").tag("dracula")
                    Text("Monokai").tag("monokai")
                    Text("Tomorrow Night").tag("tomorrowNight")
                    Text("One Dark").tag("oneDark")
                }
            }
            
            Section("Font") {
                Picker("Font Family", selection: $fontFamily) {
                    Text("Menlo").tag("Menlo")
                    Text("Monaco").tag("Monaco")
                    Text("Courier").tag("Courier")
                    Text("SF Mono").tag("SFMono")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(fontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $fontSize, in: 10...24, step: 1)
                }
            }
            
            Section("Preview") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$ ssh user@server.com")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("Connected to server.com")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("user@server:~$ ")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black)
                .cornerRadius(8)
            }
        }
        .navigationTitle("Appearance")
    }
}

#Preview {
    NavigationView {
        AppearanceSettingsView()
    }
}
