import Foundation
import Observation

@Observable
public final class RootAppModel {
    public var milestones: [Milestone]

    public init(milestones: [Milestone] = []) {
        self.milestones = milestones
    }
}

public extension RootAppModel {
    struct Milestone: Identifiable, Hashable, Sendable {
        public let id: UUID
        public var name: String
        public var status: Status
        public var due: Date?

        public init(id: UUID = .init(), name: String, status: Status = .backlog, due: Date? = nil) {
            self.id = id
            self.name = name
            self.status = status
            self.due = due
        }
    }

    enum Status: String, CaseIterable, Codable, Sendable {
        case backlog
        case inProgress
        case review
        case done
    }
}

public extension Array where Element == RootAppModel.Milestone {
    static func sample() -> [RootAppModel.Milestone] {
        [
            .init(name: "Design onboarding journey", status: .inProgress),
            .init(name: "Build MCP sync adapter", status: .review),
            .init(name: "Ship beta milestone", status: .backlog)
        ]
    }
}
