import XCTest
@testable import CafeDokoCore

final class MCPBridgeTests: XCTestCase {
    var tempDirectory: URL!
    var testFileURL: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        testFileURL = tempDirectory.appendingPathComponent("todo.mcp.json")
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testLoadTasks() throws {
        // Given
        let sampleJSON = """
        {
          "project": "TestProject",
          "version": "1.0.0",
          "updated_at": "2025-02-14T00:00:00Z",
          "owners": ["test_owner"],
          "workflow": ["backlog", "in_progress", "done"],
          "tasks": [
            {
              "id": "TEST-001",
              "title": "Test Task",
              "status": "backlog",
              "owner": "test_owner",
              "description": "This is a test task"
            }
          ]
        }
        """
        try sampleJSON.write(to: testFileURL, atomically: true, encoding: .utf8)
        
        // When
        let bridge = MCPBridge(todoFilePath: testFileURL.path)
        let document = try bridge.loadTasks()
        
        // Then
        XCTAssertEqual(document.project, "TestProject")
        XCTAssertEqual(document.tasks.count, 1)
        XCTAssertEqual(document.tasks[0].id, "TEST-001")
        XCTAssertEqual(document.tasks[0].status, .backlog)
    }
    
    func testSaveTasks() throws {
        // Given
        let bridge = MCPBridge(todoFilePath: testFileURL.path)
        let task = MCPTask(
            id: "TEST-001",
            title: "Test Task",
            status: .inProgress,
            owner: "test_owner",
            description: "Test description"
        )
        let document = MCPTodoDocument(
            project: "TestProject",
            version: "1.0.0",
            updatedAt: Date(),
            owners: ["test_owner"],
            workflow: ["backlog", "in_progress", "done"],
            tasks: [task]
        )
        
        // When
        try bridge.saveTasks(document)
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
        let loadedDocument = try bridge.loadTasks()
        XCTAssertEqual(loadedDocument.tasks.count, 1)
        XCTAssertEqual(loadedDocument.tasks[0].id, "TEST-001")
    }
    
    func testFilterTasksByStatus() throws {
        // Given
        let tasks = [
            MCPTask(id: "T1", title: "Task 1", status: .backlog, owner: "owner1", description: "Desc 1"),
            MCPTask(id: "T2", title: "Task 2", status: .inProgress, owner: "owner1", description: "Desc 2"),
            MCPTask(id: "T3", title: "Task 3", status: .done, owner: "owner2", description: "Desc 3")
        ]
        let document = MCPTodoDocument(
            project: "TestProject",
            version: "1.0.0",
            updatedAt: Date(),
            owners: ["owner1", "owner2"],
            workflow: ["backlog", "in_progress", "done"],
            tasks: tasks
        )
        let bridge = MCPBridge(todoFilePath: testFileURL.path)
        
        // When
        let inProgressTasks = bridge.tasks(withStatus: .inProgress, from: document)
        
        // Then
        XCTAssertEqual(inProgressTasks.count, 1)
        XCTAssertEqual(inProgressTasks[0].id, "T2")
    }
    
    func testUpdateTaskStatus() throws {
        // Given
        let task = MCPTask(id: "TEST-001", title: "Test", status: .backlog, owner: "owner", description: "Desc")
        var document = MCPTodoDocument(
            project: "TestProject",
            version: "1.0.0",
            updatedAt: Date(),
            owners: ["owner"],
            workflow: ["backlog", "in_progress", "done"],
            tasks: [task]
        )
        let bridge = MCPBridge(todoFilePath: testFileURL.path)
        
        // When
        try bridge.updateTaskStatus(taskId: "TEST-001", newStatus: .inProgress, in: &document)
        
        // Then
        XCTAssertEqual(document.tasks[0].status, .inProgress)
    }
    
    func testBlockedTasks() throws {
        // Given
        let tasks = [
            MCPTask(id: "T1", title: "Task 1", status: .blocked, owner: "owner", description: "Desc", blockedBy: ["T2"]),
            MCPTask(id: "T2", title: "Task 2", status: .inProgress, owner: "owner", description: "Desc"),
            MCPTask(id: "T3", title: "Task 3", status: .blocked, owner: "owner", description: "Desc", blockedBy: ["T4"])
        ]
        let document = MCPTodoDocument(
            project: "TestProject",
            version: "1.0.0",
            updatedAt: Date(),
            owners: ["owner"],
            workflow: ["backlog", "in_progress", "blocked", "done"],
            tasks: tasks
        )
        let bridge = MCPBridge(todoFilePath: testFileURL.path)
        
        // When
        let blockedTasks = bridge.blockedTasks(from: document)
        
        // Then
        XCTAssertEqual(blockedTasks.count, 2)
        XCTAssertTrue(blockedTasks.contains { $0.id == "T1" })
        XCTAssertTrue(blockedTasks.contains { $0.id == "T3" })
    }
}

