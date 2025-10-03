#!/usr/bin/env swift

import Foundation

// MCP CLI Tool for managing todo.mcp.json
// Usage:
//   swift Tools/mcp-cli/main.swift list [--status=backlog|in_progress|review|blocked|done]
//   swift Tools/mcp-cli/main.swift update <task-id> <new-status>
//   swift Tools/mcp-cli/main.swift show <task-id>

let arguments = CommandLine.arguments
let command = arguments.count > 1 ? arguments[1] : "help"

switch command {
case "list":
    listTasks()
case "update":
    updateTask()
case "show":
    showTask()
case "sync":
    syncWithMCPHost()
default:
    printHelp()
}

// MARK: - Commands

func listTasks() {
    do {
        let bridge = MCPBridge()
        let document = try bridge.loadTasks()
        
        // Parse optional --status filter
        let statusFilter: MCPTaskStatus? = {
            for arg in CommandLine.arguments where arg.starts(with: "--status=") {
                let value = String(arg.dropFirst("--status=".count))
                return MCPTaskStatus(rawValue: value)
            }
            return nil
        }()
        
        let tasks = statusFilter.map { bridge.tasks(withStatus: $0, from: document) } ?? document.tasks
        
        print("📋 Tasks in \(document.project)")
        print("───────────────────────────────────────")
        for task in tasks {
            let statusIcon = iconForStatus(task.status)
            print("\(statusIcon) [\(task.id)] \(task.title)")
            print("   Status: \(task.status.displayName) | Owner: \(task.owner)")
            if let blockedBy = task.blockedBy, !blockedBy.isEmpty {
                print("   🚫 Blocked by: \(blockedBy.joined(separator: ", "))")
            }
            print("")
        }
        print("Total: \(tasks.count) tasks")
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
}

func updateTask() {
    guard CommandLine.arguments.count >= 4 else {
        print("❌ Usage: mcp-cli update <task-id> <new-status>")
        exit(1)
    }
    
    let taskId = CommandLine.arguments[2]
    let newStatusString = CommandLine.arguments[3]
    
    guard let newStatus = MCPTaskStatus(rawValue: newStatusString) else {
        print("❌ Invalid status. Valid values: \(MCPTaskStatus.allCases.map(\.rawValue).joined(separator: ", "))")
        exit(1)
    }
    
    do {
        let bridge = MCPBridge()
        var document = try bridge.loadTasks()
        try bridge.updateTaskStatus(taskId: taskId, newStatus: newStatus, in: &document)
        try bridge.saveTasks(document)
        
        print("✅ Updated task \(taskId) to \(newStatus.displayName)")
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
}

func showTask() {
    guard CommandLine.arguments.count >= 3 else {
        print("❌ Usage: mcp-cli show <task-id>")
        exit(1)
    }
    
    let taskId = CommandLine.arguments[2]
    
    do {
        let bridge = MCPBridge()
        let document = try bridge.loadTasks()
        
        guard let task = document.tasks.first(where: { $0.id == taskId }) else {
            print("❌ Task \(taskId) not found")
            exit(1)
        }
        
        print("📌 Task Details")
        print("───────────────────────────────────────")
        print("ID:          \(task.id)")
        print("Title:       \(task.title)")
        print("Status:      \(iconForStatus(task.status)) \(task.status.displayName)")
        print("Owner:       \(task.owner)")
        print("Description: \(task.description)")
        
        if let links = task.links, !links.isEmpty {
            print("Links:")
            for link in links {
                print("  - \(link)")
            }
        }
        
        if let notes = task.notes, !notes.isEmpty {
            print("Notes:")
            for note in notes {
                print("  - \(note)")
            }
        }
        
        if let tags = task.tags, !tags.isEmpty {
            print("Tags:        \(tags.joined(separator: ", "))")
        }
        
        if let blockedBy = task.blockedBy, !blockedBy.isEmpty {
            print("Blocked by:  \(blockedBy.joined(separator: ", "))")
        }
        
        if let dueDate = task.dueDate {
            print("Due date:    \(dueDate)")
        }
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
}

func syncWithMCPHost() {
    print("🔄 Syncing with MCP host...")
    print("⚠️  MCP host sync is not yet implemented.")
    print("    This will be implemented once the MCP protocol integration is ready.")
}

func printHelp() {
    print("""
    📋 MCP CLI - Task Management Tool
    
    Usage:
      mcp-cli list [--status=<status>]     List all tasks (optionally filtered by status)
      mcp-cli show <task-id>                Show detailed information about a task
      mcp-cli update <task-id> <status>     Update task status
      mcp-cli sync                          Sync with MCP host (coming soon)
    
    Valid statuses:
      backlog, in_progress, review, blocked, done
    
    Examples:
      mcp-cli list --status=in_progress
      mcp-cli show DC-001
      mcp-cli update DC-001 done
    """)
}

func iconForStatus(_ status: MCPTaskStatus) -> String {
    switch status {
    case .backlog: return "📥"
    case .inProgress: return "🔄"
    case .review: return "👀"
    case .blocked: return "🚫"
    case .done: return "✅"
    }
}

// MARK: - Embedded MCPBridge (simplified version for CLI)

struct MCPBridge {
    enum MCPError: LocalizedError {
        case fileNotFound(String)
        case invalidJSON(Error)
        case writeError(Error)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "TODO ファイルが見つかりません: \(path)"
            case .invalidJSON(let error):
                return "JSON の解析に失敗しました: \(error.localizedDescription)"
            case .writeError(let error):
                return "ファイルの書き込みに失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    private let fileURL: URL
    
    init(todoFilePath: String = "Docs/todo.mcp.json") {
        self.fileURL = URL(fileURLWithPath: todoFilePath)
    }
    
    func loadTasks() throws -> MCPTodoDocument {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw MCPError.fileNotFound(fileURL.path)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MCPTodoDocument.self, from: data)
        } catch let decodingError {
            print("Debug: Decoding error details: \(decodingError)")
            throw MCPError.invalidJSON(decodingError)
        }
    }
    
    func saveTasks(_ document: MCPTodoDocument) throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(document)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw MCPError.writeError(error)
        }
    }
    
    func tasks(withStatus status: MCPTaskStatus, from document: MCPTodoDocument) -> [MCPTask] {
        document.tasks.filter { $0.status == status }
    }
    
    func updateTaskStatus(
        taskId: String,
        newStatus: MCPTaskStatus,
        in document: inout MCPTodoDocument
    ) throws {
        guard let index = document.tasks.firstIndex(where: { $0.id == taskId }) else {
            throw MCPError.fileNotFound("Task ID: \(taskId)")
        }
        document.tasks[index].status = newStatus
        document.updatedAt = Date()
    }
}

struct MCPTodoDocument: Codable {
    var project: String
    var version: String
    var updatedAt: Date
    var owners: [String]
    var workflow: [String]
    var tasks: [MCPTask]
    
    enum CodingKeys: String, CodingKey {
        case project, version
        case updatedAt = "updated_at"
        case owners, workflow, tasks
    }
}

struct MCPTask: Codable {
    let id: String
    var title: String
    var status: MCPTaskStatus
    var owner: String
    var description: String
    var links: [String]?
    var notes: [String]?
    var tags: [String]?
    var blockedBy: [String]?
    var dueDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, status, owner, description, links, notes, tags
        case blockedBy = "blocked_by"
        case dueDate = "due_date"
    }
}

enum MCPTaskStatus: String, Codable, CaseIterable {
    case backlog
    case inProgress = "in_progress"
    case review
    case blocked
    case done
    
    var displayName: String {
        switch self {
        case .backlog: return "Backlog"
        case .inProgress: return "In Progress"
        case .review: return "Review"
        case .blocked: return "Blocked"
        case .done: return "Done"
        }
    }
}

