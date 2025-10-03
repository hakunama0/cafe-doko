import XCTest
import CafeDokoCore

final class CafeDokoAppTests: XCTestCase {
    func testMilestoneSampleGeneratesThreeItems() {
        let milestones = [RootAppModel.Milestone].sample()
        XCTAssertEqual(milestones.count, 3)
    }
}
