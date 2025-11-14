//
//  DiagnosticsManager.swift
//  Draw With Friends
//
//  Diagnostics system for debugging sync issues
//

import Foundation
import Combine
import UIKit

class DiagnosticsManager: ObservableObject {
    static let shared = DiagnosticsManager()
    
    @Published var logs: [DiagnosticLog] = []
    @Published var metrics: DiagnosticMetrics = DiagnosticMetrics()
    
    private let maxLogs = 500 // Keep last 500 log entries
    private var sessionStartTime = Date()
    
    struct DiagnosticLog: Identifiable {
        let id = UUID()
        let timestamp: Date
        let category: LogCategory
        let message: String
        
        enum LogCategory: String {
            case connection = "🔌"
            case strokeSent = "📤"
            case strokeReceived = "📥"
            case rebuild = "🔄"
            case sync = "⏱️"
            case echo = "🔊"
            case error = "❌"
            case warning = "⚠️"
            case info = "ℹ️"
            case userAction = "👆"
        }
        
        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
        
        var displayText: String {
            "\(category.rawValue) \(formattedTime) \(message)"
        }
    }
    
    struct DiagnosticMetrics: Codable {
        var strokesSent = 0
        var strokesReceived = 0
        var echoesGenerated = 0
        var rebuildsExecuted = 0
        var rebuildsDeferred = 0
        var syncTimerFires = 0
        var errors = 0
        var lastStrokeSentTime: Date?
        var lastStrokeReceivedTime: Date?
        var lastEchoTime: Date?
        var lastRebuildTime: Date?
        var currentKnownStrokes = 0
        var currentCanvasStrokes = 0
        var isUserDrawing = false
        var isRebuilding = false
        var isEchoEnabled = false
        var echoCount = 0
        var connectionStatus = "Unknown"
        var roomCode: String?
        var userId: String?
        var deviceType: String = ""
        
        var summary: String {
            """
            === DIAGNOSTIC METRICS ===
            Room: \(roomCode ?? "None")
            User: \(userId?.prefix(8) ?? "None")
            Device: \(deviceType)
            Connection: \(connectionStatus)
            
            Strokes Sent: \(strokesSent)
            Strokes Received: \(strokesReceived)
            Echo Mode: \(isEchoEnabled ? "ON (\(echoCount == 0 ? "∞" : "\(echoCount)x"))" : "OFF")
            Echoes Generated: \(echoesGenerated)
            Known Strokes: \(currentKnownStrokes)
            Canvas Strokes: \(currentCanvasStrokes)
            
            Rebuilds: \(rebuildsExecuted) executed, \(rebuildsDeferred) deferred
            Sync Timer Fires: \(syncTimerFires)
            Errors: \(errors)
            
            User Drawing: \(isUserDrawing ? "YES" : "NO")
            Currently Rebuilding: \(isRebuilding ? "YES" : "NO")
            
            Last Stroke Sent: \(formatTime(lastStrokeSentTime))
            Last Stroke Received: \(formatTime(lastStrokeReceivedTime))
            Last Echo: \(formatTime(lastEchoTime))
            Last Rebuild: \(formatTime(lastRebuildTime))
            """
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
    }
    
    private init() {
        #if targetEnvironment(simulator)
        metrics.deviceType = "Simulator"
        #else
        metrics.deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        #endif
    }
    
    // MARK: - Logging Methods
    
    func log(_ message: String, category: DiagnosticLog.LogCategory) {
        let log = DiagnosticLog(timestamp: Date(), category: category, message: message)
        
        DispatchQueue.main.async {
            self.logs.append(log)
            
            // Keep only recent logs
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }
            
            // Update error count
            if category == .error {
                self.metrics.errors += 1
            }
        }
        
        // Also print to console
        print("\(log.displayText)")
    }
    
    func logStrokeSent(strokeId: String, userId: String) {
        log("Sent stroke \(strokeId.prefix(8)) from user \(userId.prefix(8))", category: .strokeSent)
        DispatchQueue.main.async {
            self.metrics.strokesSent += 1
            self.metrics.lastStrokeSentTime = Date()
        }
    }
    
    func logStrokeReceived(strokeId: String, fromUser: String, isOwn: Bool) {
        if isOwn {
            log("Received own stroke \(strokeId.prefix(8)) (echo)", category: .strokeReceived)
        } else {
            log("Received stroke \(strokeId.prefix(8)) from \(fromUser.prefix(8))", category: .strokeReceived)
            DispatchQueue.main.async {
                self.metrics.strokesReceived += 1
                self.metrics.lastStrokeReceivedTime = Date()
            }
        }
    }
    
    func logRebuild(strokeCount: Int, deferred: Bool = false) {
        if deferred {
            log("Rebuild DEFERRED (user drawing)", category: .rebuild)
            DispatchQueue.main.async {
                self.metrics.rebuildsDeferred += 1
            }
        } else {
            log("Rebuild executed: \(strokeCount) strokes", category: .rebuild)
            DispatchQueue.main.async {
                self.metrics.rebuildsExecuted += 1
                self.metrics.lastRebuildTime = Date()
            }
        }
    }
    
    func logSyncTimer(canvasStrokes: Int, knownStrokes: Int, newLocal: Int) {
        if newLocal > 0 {
            log("Sync: Found \(newLocal) new local strokes (canvas:\(canvasStrokes), known:\(knownStrokes))", category: .sync)
        }
        DispatchQueue.main.async {
            self.metrics.syncTimerFires += 1
            self.metrics.currentCanvasStrokes = canvasStrokes
            self.metrics.currentKnownStrokes = knownStrokes
        }
    }
    
    func logUserDrawing(started: Bool) {
        log(started ? "User STARTED drawing" : "User FINISHED drawing", category: .userAction)
        DispatchQueue.main.async {
            self.metrics.isUserDrawing = started
        }
    }
    
    func logConnection(status: String) {
        log("Connection: \(status)", category: .connection)
        DispatchQueue.main.async {
            self.metrics.connectionStatus = status
        }
    }
    
    func logError(_ message: String) {
        log("ERROR: \(message)", category: .error)
    }
    
    func logWarning(_ message: String) {
        log("WARNING: \(message)", category: .warning)
    }
    
    func logInfo(_ message: String) {
        log(message, category: .info)
    }
    
    func logEcho(strokeId: String, originalStrokeId: String, count: Int) {
        log("Echo: \(strokeId.prefix(8)) from \(originalStrokeId.prefix(8)) (count: \(count))", category: .echo)
        DispatchQueue.main.async {
            self.metrics.echoesGenerated += 1
            self.metrics.lastEchoTime = Date()
        }
    }
    
    func logEchoStateChange(enabled: Bool, count: Int) {
        let state = enabled ? "ENABLED" : "DISABLED"
        let countStr = count == 0 ? "∞" : "\(count)x"
        log("Echo mode \(state) (\(countStr))", category: .echo)
        DispatchQueue.main.async {
            self.metrics.isEchoEnabled = enabled
            self.metrics.echoCount = count
        }
    }
    
    // MARK: - Metrics Updates
    
    func updateMetrics(roomCode: String?, userId: String?, isRebuilding: Bool = false) {
        DispatchQueue.main.async {
            if let roomCode = roomCode {
                self.metrics.roomCode = roomCode
            }
            if let userId = userId {
                self.metrics.userId = userId
            }
            self.metrics.isRebuilding = isRebuilding
        }
    }
    
    // MARK: - Export
    
    func exportDiagnostics() -> String {
        let header = """
        ========================================
        DRAW WITH FRIENDS - DIAGNOSTIC REPORT
        ========================================
        Session Start: \(sessionStartTime)
        Report Time: \(Date())
        Session Duration: \(Int(Date().timeIntervalSince(sessionStartTime)))s
        
        """
        
        let metricsSection = metrics.summary + "\n\n"
        
        let logsHeader = """
        === DETAILED LOGS (\(logs.count) entries) ===
        
        """
        
        let logsSection = logs.map { $0.displayText }.joined(separator: "\n")
        
        return header + metricsSection + logsHeader + logsSection
    }
    
    func resetSession() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.metrics = DiagnosticMetrics()
            self.metrics.deviceType = self.metrics.deviceType // Preserve device type
            self.sessionStartTime = Date()
            self.log("Diagnostics session reset", category: .info)
        }
    }
}

