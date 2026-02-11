//
//  SimpleTerminalView.swift
//  SSHTerminal
//
//  Simplified terminal view for beta

import SwiftUI

struct SimpleTerminalView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @State private var input = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Output area
            ScrollView {
                ScrollViewReader { proxy in
                    Text(viewModel.session.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("bottom")
                        .onChange(of: viewModel.session.output) { _ in
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                }
            }
            .background(Color.black)
            
            // Input area
            HStack {
                TextField("Enter command", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        sendCommand()
                    }
                
                Button("Send") {
                    sendCommand()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle("Terminal")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendCommand() {
        guard !input.isEmpty else { return }
        Task {
            await viewModel.sendInput(input + "\n")
            input = ""
        }
    }
}
