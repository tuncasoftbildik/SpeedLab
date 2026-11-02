import XCTest
@testable import SpeedLab

final class SampleBufferTests: XCTestCase {
    func test_capacityDropsOldest() {
        var b = SampleBuffer(capacity: 3)
        [1, 2, 3, 4].forEach { b.append($0) }
        XCTAssertEqual(b.values, [2, 3, 4])
    }

    func test_defaultCapacity60() {
        XCTAssertEqual(SampleBuffer().capacity, 60)
        XCTAssertTrue(SampleBuffer().values.isEmpty)
    }

    func test_reset() {
        var b = SampleBuffer(capacity: 3)
        b.append(5); b.reset()
        XCTAssertTrue(b.values.isEmpty)
    }
}
