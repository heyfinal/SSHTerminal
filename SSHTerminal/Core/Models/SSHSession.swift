//
//  SSHSession.swift
//  SSHTerminal
//
//  Created by Daniel on 2024.
//

import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(Error)
    
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

class SSHSession: ObservableObject, Identifiable {
    let id: UUID
    let server: ServerProfile
    @Published var state: ConnectionState
    @Published var output: String
    
    init(id: UUID = UUID(), server: ServerProfile) {
        self.id = id
        self.server = server
        self.state = .disconnected
        self.output = ""
    }
    
    func appendOutput(_ text: String) {
        output += text
    }
}
