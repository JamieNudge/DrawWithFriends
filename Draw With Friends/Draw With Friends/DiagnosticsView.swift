//
//  DiagnosticsView.swift
//  Draw With Friends
//
//  UI for viewing and exporting diagnostics
//

import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var diagnostics = DiagnosticsManager.shared
    @State private var showingFullLogs = false
    @State private var showCopyConfirmation = false
    var onDismiss: (() -> Void)? = nil  // Callback to dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📊 Diagnostics")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingFullLogs.toggle()
                }) {
                    Image(systemName: showingFullLogs ? "list.bullet.circle.fill" : "list.bullet.circle")
                        .font(.title3)
                }
                
                Button(action: copyDiagnostics) {
                    Image(systemName: showCopyConfirmation ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(showCopyConfirmation ? .green : .blue)
                }
                
                Button(action: {
                    diagnostics.resetSession()
                }) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                // CLOSE BUTTON
                Button(action: {
                    onDismiss?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            
            if showingFullLogs {
                // Full log view
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(diagnostics.logs) { log in
                                Text(log.displayText)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(colorForCategory(log.category))
                                    .id(log.id)
                            }
                        }
                        .padding()
                        .onAppear {
                            if let lastLog = diagnostics.logs.last {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: diagnostics.logs.count) { _ in
                            if let lastLog = diagnostics.logs.last {
                                withAnimation {
                                    proxy.scrollTo(lastLog.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color.black.opacity(0.85))
            } else {
                // Metrics dashboard
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Connection Status
                        HStack {
                            Text("🔌")
                            Text(diagnostics.metrics.connectionStatus)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Circle()
                                .fill(connectionColor)
                                .frame(width: 12, height: 12)
                        }
                        
                        Divider()
                        
                        // Room Info
                        if let roomCode = diagnostics.metrics.roomCode {
                            metricRow("Room", roomCode)
                        }
                        if let userId = diagnostics.metrics.userId {
                            metricRow("User ID", String(userId.prefix(8)))
                        }
                        metricRow("Device", diagnostics.metrics.deviceType)
                        
                        Divider()
                        
                        // Stroke Metrics
                        metricRow("Strokes Sent", "\(diagnostics.metrics.strokesSent)")
                        metricRow("Strokes Received", "\(diagnostics.metrics.strokesReceived)")
                        
                        // Echo Metrics
                        if diagnostics.metrics.isEchoEnabled {
                            HStack {
                                Text("🔊 Echo Mode:")
                                    .font(.caption)
                                Spacer()
                                Text(diagnostics.metrics.echoCount == 0 ? "∞" : "\(diagnostics.metrics.echoCount)x")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.pink)
                            }
                            metricRow("Echoes Generated", "\(diagnostics.metrics.echoesGenerated)")
                        }
                        
                        metricRow("Known Strokes", "\(diagnostics.metrics.currentKnownStrokes)")
                        metricRow("Canvas Strokes", "\(diagnostics.metrics.currentCanvasStrokes)")
                        
                        Divider()
                        
                        // Rebuild Metrics
                        metricRow("Rebuilds", "\(diagnostics.metrics.rebuildsExecuted)")
                        metricRow("Deferred", "\(diagnostics.metrics.rebuildsDeferred)")
                        metricRow("Sync Ticks", "\(diagnostics.metrics.syncTimerFires)")
                        
                        Divider()
                        
                        // Status
                        HStack {
                            Text("Drawing:")
                            Spacer()
                            Text(diagnostics.metrics.isUserDrawing ? "YES" : "NO")
                                .fontWeight(.bold)
                                .foregroundColor(diagnostics.metrics.isUserDrawing ? .green : .gray)
                        }
                        
                        HStack {
                            Text("Rebuilding:")
                            Spacer()
                            Text(diagnostics.metrics.isRebuilding ? "YES" : "NO")
                                .fontWeight(.bold)
                                .foregroundColor(diagnostics.metrics.isRebuilding ? .orange : .gray)
                        }
                        
                        if diagnostics.metrics.errors > 0 {
                            HStack {
                                Text("Errors:")
                                Spacer()
                                Text("\(diagnostics.metrics.errors)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Divider()
                        
                        // Timing Info
                        Text("Last Activity")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        timingRow("Sent", diagnostics.metrics.lastStrokeSentTime)
                        timingRow("Received", diagnostics.metrics.lastStrokeReceivedTime)
                        if diagnostics.metrics.isEchoEnabled {
                            timingRow("Echo", diagnostics.metrics.lastEchoTime)
                        }
                        timingRow("Rebuild", diagnostics.metrics.lastRebuildTime)
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
                .background(Color.black.opacity(0.85))
            }
        }
        .foregroundColor(.white)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
    
    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
        }
    }
    
    private func timingRow(_ label: String, _ date: Date?) -> some View {
        HStack {
            Text("  \(label):")
                .font(.caption2)
                .foregroundColor(.gray)
            Spacer()
            Text(formatTime(date))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(date == nil ? .gray : .white)
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval/60))m ago"
        } else {
            return "\(Int(interval/3600))h ago"
        }
    }
    
    private var connectionColor: Color {
        switch diagnostics.metrics.connectionStatus {
        case "Connected", "Active":
            return .green
        case "Connecting":
            return .yellow
        case "Disconnected", "Error":
            return .red
        default:
            return .gray
        }
    }
    
    private func colorForCategory(_ category: DiagnosticsManager.DiagnosticLog.LogCategory) -> Color {
        switch category {
        case .connection: return .cyan
        case .strokeSent: return .green
        case .strokeReceived: return .blue
        case .rebuild: return .orange
        case .sync: return .purple
        case .echo: return .pink
        case .error: return .red
        case .warning: return .yellow
        case .info: return .white
        case .userAction: return .mint
        }
    }
    
    private func copyDiagnostics() {
        let report = diagnostics.exportDiagnostics()
        UIPasteboard.general.string = report
        
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyConfirmation = false
        }
    }
}

// Compact floating button to toggle diagnostics
struct DiagnosticsToggleButton: View {
    @Binding var isShowing: Bool
    @ObservedObject var diagnostics = DiagnosticsManager.shared
    
    var body: some View {
        Button(action: {
            isShowing.toggle()
        }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16))
                    
                    if diagnostics.metrics.errors > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
                .foregroundColor(.white)
            }
            .shadow(radius: 5)
        }
    }
}

#Preview {
    DiagnosticsView()
}


