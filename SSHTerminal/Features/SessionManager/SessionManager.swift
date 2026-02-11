//
//  SessionManager.swift
//  SSHTerminal
//
//  Phase 5: Advanced Session Management
//

import Foundation
import Combine

enum SessionRecordingState {
    case notRecording
    case recording(startTime: Date, outputSize: Int)
    case paused(startTime: Date, pausedAt: Date, outputSize: Int)
}

struct SessionRecording: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let serverName: String
    let startTime: Date
    let endTime: Date
    let output: String
    let commandCount: Int
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var displayDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    var fileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(output.utf8.count), countStyle: .file)
    }
}

@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var sessions: [SSHSession] = []
    @Published var activeSessionId: UUID?
    @Published var recordings: [SessionRecording] = []
    
    private var recordingStates: [UUID: SessionRecordingState] = [:]
    private var recordedOutputs: [UUID: String] = [:]
    private var commandCounts: [UUID: Int] = [:]
    
    private init() {
        loadRecordings()
    }
    
    // MARK: - Session Management
    
    func addSession(_ session: SSHSession) {
        sessions.append(session)
        activeSessionId = session.id
    }
    
    func removeSession(_ session: SSHSession) {
        stopRecording(session.id)
        sessions.removeAll { $0.id == session.id }
        
        if activeSessionId == session.id {
            activeSessionId = sessions.first?.id
        }
    }
    
    func switchToSession(_ sessionId: UUID) {
        activeSessionId = sessionId
    }
    
    func activeSession() -> SSHSession? {
        sessions.first { $0.id == activeSessionId }
    }
    
    // MARK: - Session Recording
    
    func startRecording(_ sessionId: UUID) {
        recordingStates[sessionId] = .recording(startTime: Date(), outputSize: 0)
        recordedOutputs[sessionId] = ""
        commandCounts[sessionId] = 0
    }
    
    func stopRecording(_ sessionId: UUID) {
        guard case .recording(let startTime, _) = recordingStates[sessionId],
              let output = recordedOutputs[sessionId],
              let session = sessions.first(where: { $0.id == sessionId }) else {
            return
        }
        
        let recording = SessionRecording(
            id: UUID(),
            sessionId: sessionId,
            serverName: session.server.name,
            startTime: startTime,
            endTime: Date(),
            output: output,
            commandCount: commandCounts[sessionId] ?? 0
        )
        
        recordings.insert(recording, at: 0)
        saveRecordings()
        
        // Clean up
        recordingStates.removeValue(forKey: sessionId)
        recordedOutputs.removeValue(forKey: sessionId)
        commandCounts.removeValue(forKey: sessionId)
    }
    
    func pauseRecording(_ sessionId: UUID) {
        guard case .recording(let startTime, let outputSize) = recordingStates[sessionId] else {
            return
        }
        
        recordingStates[sessionId] = .paused(startTime: startTime, pausedAt: Date(), outputSize: outputSize)
    }
    
    func resumeRecording(_ sessionId: UUID) {
        guard case .paused(let startTime, _, let outputSize) = recordingStates[sessionId] else {
            return
        }
        
        recordingStates[sessionId] = .recording(startTime: startTime, outputSize: outputSize)
    }
    
    func isRecording(_ sessionId: UUID) -> Bool {
        if case .recording = recordingStates[sessionId] {
            return true
        }
        return false
    }
    
    func recordingState(_ sessionId: UUID) -> SessionRecordingState {
        recordingStates[sessionId] ?? .notRecording
    }
    
    func appendToRecording(_ sessionId: UUID, output: String) {
        guard isRecording(sessionId) else { return }
        
        recordedOutputs[sessionId, default: ""] += output
        
        if case .recording(let startTime, let outputSize) = recordingStates[sessionId] {
            let newSize = outputSize + output.utf8.count
            recordingStates[sessionId] = .recording(startTime: startTime, outputSize: newSize)
        }
    }
    
    func incrementCommandCount(_ sessionId: UUID) {
        guard isRecording(sessionId) else { return }
        commandCounts[sessionId, default: 0] += 1
    }
    
    // MARK: - Recording Management
    
    func deleteRecording(_ recording: SessionRecording) {
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
    
    func exportRecording(_ recording: SessionRecording) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let filename = "session-\(recording.serverName)-\(formatter.string(from: recording.startTime)).txt"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        var content = """
        SSH Terminal Session Recording
        Server: \(recording.serverName)
        Start: \(recording.startTime)
        End: \(recording.endTime)
        Duration: \(recording.displayDuration)
        Commands: \(recording.commandCount)
        
        ==================== OUTPUT ====================
        
        """
        
        content += recording.output
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
    
    // MARK: - Session Restore
    
    func saveSessionState() {
        let sessionStates = sessions.map { session in
            [
                "id": session.id.uuidString,
                "serverId": session.server.id.uuidString,
                "serverName": session.server.name,
                "output": session.output
            ]
        }
        
        UserDefaults.standard.set(sessionStates, forKey: "saved_sessions")
        UserDefaults.standard.set(activeSessionId?.uuidString, forKey: "active_session_id")
    }
    
    func restoreSessionState() -> [[String: String]]? {
        UserDefaults.standard.array(forKey: "saved_sessions") as? [[String: String]]
    }
    
    func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: "saved_sessions")
        UserDefaults.standard.removeObject(forKey: "active_session_id")
    }
    
    // MARK: - Persistence
    
    private func loadRecordings() {
        if let data = UserDefaults.standard.data(forKey: "session_recordings"),
           let loaded = try? JSONDecoder().decode([SessionRecording].self, from: data) {
            recordings = loaded
        }
    }
    
    private func saveRecordings() {
        if let data = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(data, forKey: "session_recordings")
        }
    }
}

// MARK: - SSHSession Extension

extension SSHSession {
    @MainActor
    func startRecording() {
        SessionManager.shared.startRecording(id)
    }
    
    @MainActor
    func stopRecording() {
        SessionManager.shared.stopRecording(id)
    }
    
    @MainActor
    func isRecording() -> Bool {
        SessionManager.shared.isRecording(id)
    }
}
