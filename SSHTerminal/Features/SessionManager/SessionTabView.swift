//
//  SessionTabView.swift
//  SSHTerminal
//
//  Phase 5: Tabbed Session Interface
//

import SwiftUI

struct SessionTabView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var showingAddSession = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if sessionManager.sessions.count > 1 {
                sessionTabBar
                Divider()
            }
            
            // Active session view
            if let activeId = sessionManager.activeSessionId,
               let session = sessionManager.sessions.first(where: { $0.id == activeId }) {
                TerminalView(session: session)
            } else {
                emptyState
            }
        }
    }
    
    private var sessionTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sessionManager.sessions) { session in
                    SessionTab(
                        session: session,
                        isActive: session.id == sessionManager.activeSessionId,
                        onSelect: {
                            sessionManager.switchToSession(session.id)
                        },
                        onClose: {
                            sessionManager.removeSession(session)
                        }
                    )
                }
                
                // Add session button
                Button {
                    showingAddSession = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
        .sheet(isPresented: $showingAddSession) {
            // Navigate to server list
            Text("Add Session")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Active Sessions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Connect to a server to start a session")
                .foregroundColor(.secondary)
            
            Button("Connect to Server") {
                showingAddSession = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Session Tab

struct SessionTab: View {
    let session: SSHSession
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Server name
            Text(session.server.name)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .lineLimit(1)
            
            // Close button
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.blue.opacity(0.2) : Color(.systemGray5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
    
    private var statusColor: Color {
        switch session.state {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .failed:
            return .red
        }
    }
}

// MARK: - Recording Controls

struct SessionRecordingControls: View {
    let session: SSHSession
    @StateObject private var sessionManager = SessionManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            switch sessionManager.recordingState(session.id) {
            case .notRecording:
                Button {
                    sessionManager.startRecording(session.id)
                } label: {
                    Label("Record", systemImage: "record.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
            case .recording(let startTime, let outputSize):
                HStack(spacing: 8) {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(formatDuration(Date().timeIntervalSince(startTime)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(ByteCountFormatter.string(fromByteCount: Int64(outputSize), countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        sessionManager.pauseRecording(session.id)
                    } label: {
                        Image(systemName: "pause.circle.fill")
                    }
                    
                    Button {
                        sessionManager.stopRecording(session.id)
                    } label: {
                        Image(systemName: "stop.circle.fill")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
            case .paused:
                HStack(spacing: 8) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        sessionManager.resumeRecording(session.id)
                    } label: {
                        Image(systemName: "play.circle.fill")
                    }
                    
                    Button {
                        sessionManager.stopRecording(session.id)
                    } label: {
                        Image(systemName: "stop.circle.fill")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Session Recordings View

struct SessionRecordingsView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedRecording: SessionRecording?
    @State private var showingExport = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                if sessionManager.recordings.isEmpty {
                    emptyState
                } else {
                    ForEach(sessionManager.recordings) { recording in
                        RecordingRow(recording: recording)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRecording = recording
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    sessionManager.deleteRecording(recording)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    exportRecording(recording)
                                } label: {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Session Recordings")
            .sheet(item: $selectedRecording) { recording in
                RecordingDetailView(recording: recording)
            }
            .sheet(isPresented: $showingExport) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Recordings")
                .font(.headline)
            
            Text("Start recording a session to save the output")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
    
    private func exportRecording(_ recording: SessionRecording) {
        if let url = sessionManager.exportRecording(recording) {
            exportURL = url
            showingExport = true
        }
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: SessionRecording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.serverName)
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(recording.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Label(recording.displayDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(recording.commandCount) commands", systemImage: "command")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(recording.fileSize, systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Recording Detail View

struct RecordingDetailView: View {
    let recording: SessionRecording
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Metadata
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Server", value: recording.serverName)
                            InfoRow(label: "Started", value: formatFullDate(recording.startTime))
                            InfoRow(label: "Ended", value: formatFullDate(recording.endTime))
                            InfoRow(label: "Duration", value: recording.displayDuration)
                            InfoRow(label: "Commands", value: "\(recording.commandCount)")
                            InfoRow(label: "Size", value: recording.fileSize)
                        }
                    }
                    .padding()
                    
                    // Output
                    GroupBox("Output") {
                        ScrollView {
                            Text(recording.output)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 400)
                    }
                    .padding()
                }
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
