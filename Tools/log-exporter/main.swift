#!/usr/bin/env swift

import Foundation
import OSLog

// Log Exporter for CafeDoko App
// Usage:
//   swift Tools/log-exporter/main.swift [--format=json|text] [--hours=24]

@available(macOS 12.0, iOS 15.0, *)
func exportLogs() throws {
    let arguments = CommandLine.arguments
    
    // Parse arguments
    let format = parseArgument(key: "--format", defaultValue: "text")
    let hoursString = parseArgument(key: "--hours", defaultValue: "24")
    guard let hours = Int(hoursString) else {
        print("❌ Invalid --hours value: \(hoursString)")
        exit(1)
    }
    
    // Setup OSLogStore
    let logStore = try OSLogStore(scope: .currentProcessIdentifier)
    let startDate = Date().addingTimeInterval(-Double(hours) * 3600)
    let predicate = NSPredicate(format: "subsystem == %@", "com.cafedoko.app")
    
    let entries = try logStore.getEntries(at: logStore.position(date: startDate), matching: predicate)
    
    // Export logs
    if format == "json" {
        exportAsJSON(entries: entries)
    } else {
        exportAsText(entries: entries)
    }
}

@available(macOS 12.0, iOS 15.0, *)
func exportAsText(entries: OSLogEntryLog.Sequence) {
    print("📊 CafeDoko Logs")
    print(String(repeating: "=", count: 80))
    
    var count = 0
    for entry in entries {
        guard let logEntry = entry as? OSLogEntryLog else { continue }
        
        let timestamp = ISO8601DateFormatter().string(from: logEntry.date)
        let level = levelIcon(logEntry.level)
        let category = logEntry.category
        let message = logEntry.composedMessage
        
        print("[\(timestamp)] \(level) [\(category)] \(message)")
        count += 1
    }
    
    print(String(repeating: "=", count: 80))
    print("Total: \(count) entries")
}

@available(macOS 12.0, iOS 15.0, *)
func exportAsJSON(entries: OSLogEntryLog.Sequence) {
    var logs: [[String: Any]] = []
    
    for entry in entries {
        guard let logEntry = entry as? OSLogEntryLog else { continue }
        
        let log: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: logEntry.date),
            "level": levelString(logEntry.level),
            "category": logEntry.category,
            "message": logEntry.composedMessage,
            "process": logEntry.process,
            "processID": logEntry.processIdentifier,
            "threadID": logEntry.threadIdentifier
        ]
        logs.append(log)
    }
    
    let jsonData = try! JSONSerialization.data(withJSONObject: logs, options: .prettyPrinted)
    print(String(data: jsonData, encoding: .utf8)!)
}

@available(macOS 12.0, iOS 15.0, *)
func levelIcon(_ level: OSLogEntryLog.Level) -> String {
    switch level {
    case .undefined: return "❔"
    case .debug: return "🐛"
    case .info: return "ℹ️"
    case .notice: return "📢"
    case .error: return "❌"
    case .fault: return "💥"
    @unknown default: return "❓"
    }
}

@available(macOS 12.0, iOS 15.0, *)
func levelString(_ level: OSLogEntryLog.Level) -> String {
    switch level {
    case .undefined: return "undefined"
    case .debug: return "debug"
    case .info: return "info"
    case .notice: return "notice"
    case .error: return "error"
    case .fault: return "fault"
    @unknown default: return "unknown"
    }
}

func parseArgument(key: String, defaultValue: String) -> String {
    for arg in CommandLine.arguments where arg.starts(with: "\(key)=") {
        return String(arg.dropFirst("\(key)=".count))
    }
    return defaultValue
}

func printHelp() {
    print("""
    📊 Log Exporter for CafeDoko
    
    Usage:
      log-exporter [--format=json|text] [--hours=24]
    
    Options:
      --format    Output format (json or text). Default: text
      --hours     Number of hours to look back. Default: 24
    
    Examples:
      swift Tools/log-exporter/main.swift
      swift Tools/log-exporter/main.swift --format=json --hours=48
      swift Tools/log-exporter/main.swift --format=json > logs.json
    
    Note:
      This tool requires macOS 12.0+ or iOS 15.0+
      Run the app first to generate logs, then use this tool to export them.
    """)
}

// Main
if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    printHelp()
    exit(0)
}

if #available(macOS 12.0, iOS 15.0, *) {
    do {
        try exportLogs()
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
} else {
    print("❌ This tool requires macOS 12.0+ or iOS 15.0+")
    exit(1)
}

