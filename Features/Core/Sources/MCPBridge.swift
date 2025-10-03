import Foundation

/// MCP (Model Context Protocol) Bridge for todo.mcp.json synchronization
public struct MCPBridge {
    public enum MCPError: LocalizedError {
        case fileNotFound(String)
        case invalidJSON(Error)
        case writeError(Error)
        
        public var errorDescription: String? {
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
    
    public init(todoFilePath: String = "Docs/todo.mcp.json") {
        self.fileURL = URL(fileURLWithPath: todoFilePath)
    }
    
    // MARK: - Read
    
    /// Load todo.mcp.json from disk
    public func loadTasks() throws -> MCPTodoDocument {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw MCPError.fileNotFound(fileURL.path)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MCPTodoDocument.self, from: data)
        } catch let error as DecodingError {
            throw MCPError.invalidJSON(error)
        } catch {
            throw MCPError.invalidJSON(error)
        }
    }
    
    // MARK: - Write
    
    /// Save todo.mcp.json to disk
    public func saveTasks(_ document: MCPTodoDocument) throws {
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
    
    // MARK: - Query
    
    /// Get tasks by status
    public func tasks(withStatus status: MCPTaskStatus, from document: MCPTodoDocument) -> [MCPTask] {
        document.tasks.filter { $0.status == status }
    }
    
    /// Get tasks by owner
    public func tasks(withOwner owner: String, from document: MCPTodoDocument) -> [MCPTask] {
        document.tasks.filter { $0.owner == owner }
    }
    
    /// Get blocked tasks
    public func blockedTasks(from document: MCPTodoDocument) -> [MCPTask] {
        document.tasks.filter { $0.status == .blocked }
    }
    
    // MARK: - Update
    
    /// Update task status by ID
    public func updateTaskStatus(
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

// MARK: - Models

public struct MCPTodoDocument: Codable {
    public var project: String
    public var version: String
    public var updatedAt: Date
    public var owners: [String]
    public var workflow: [String]
    public var tasks: [MCPTask]
    
    enum CodingKeys: String, CodingKey {
        case project
        case version
        case updatedAt = "updated_at"
        case owners
        case workflow
        case tasks
    }
    
    public init(
        project: String,
        version: String,
        updatedAt: Date,
        owners: [String],
        workflow: [String],
        tasks: [MCPTask]
    ) {
        self.project = project
        self.version = version
        self.updatedAt = updatedAt
        self.owners = owners
        self.workflow = workflow
        self.tasks = tasks
    }
}

public struct MCPTask: Codable, Identifiable {
    public let id: String
    public var title: String
    public var status: MCPTaskStatus
    public var owner: String
    public var description: String
    public var links: [String]?
    public var notes: [String]?
    public var tags: [String]?
    public var blockedBy: [String]?
    public var dueDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case owner
        case description
        case links
        case notes
        case tags
        case blockedBy = "blocked_by"
        case dueDate = "due_date"
    }
    
    public init(
        id: String,
        title: String,
        status: MCPTaskStatus,
        owner: String,
        description: String,
        links: [String]? = nil,
        notes: [String]? = nil,
        tags: [String]? = nil,
        blockedBy: [String]? = nil,
        dueDate: String? = nil
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.owner = owner
        self.description = description
        self.links = links
        self.notes = notes
        self.tags = tags
        self.blockedBy = blockedBy
        self.dueDate = dueDate
    }
}

public enum MCPTaskStatus: String, Codable, CaseIterable {
    case backlog
    case inProgress = "in_progress"
    case review
    case blocked
    case done
    
    public var displayName: String {
        switch self {
        case .backlog: return "Backlog"
        case .inProgress: return "In Progress"
        case .review: return "Review"
        case .blocked: return "Blocked"
        case .done: return "Done"
        }
    }
}

