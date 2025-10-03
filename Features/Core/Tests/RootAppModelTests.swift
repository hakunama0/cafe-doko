import XCTest
@testable import CafeDokoCore

final class RootAppModelTests: XCTestCase {
    func testAppendingMilestoneUpdatesCollection() {
        var model = RootAppModel(milestones: [])
        model.milestones.append(.init(name: "Test"))
        XCTAssertEqual(model.milestones.count, 1)
        XCTAssertEqual(model.milestones.first?.name, "Test")
    }
}
