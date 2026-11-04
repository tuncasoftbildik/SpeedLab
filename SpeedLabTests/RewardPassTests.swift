import XCTest
@testable import SpeedLab

final class RewardPassTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func test_inactiveWithoutDate() {
        XCTAssertFalse(RewardPass.isActive(until: nil, now: now))
        XCTAssertEqual(RewardPass.remaining(until: nil, now: now), 0)
    }

    func test_activeUntilExpiry() {
        let until = now.addingTimeInterval(60)
        XCTAssertTrue(RewardPass.isActive(until: until, now: now))
        XCTAssertFalse(RewardPass.isActive(until: until, now: until))
        XCTAssertEqual(RewardPass.remaining(until: until, now: now), 60)
    }

    func test_extendFromExpiredStartsNow() {
        let old = now.addingTimeInterval(-100)
        XCTAssertEqual(RewardPass.extended(from: old, now: now), now.addingTimeInterval(RewardPass.duration))
        XCTAssertEqual(RewardPass.extended(from: nil, now: now), now.addingTimeInterval(RewardPass.duration))
    }

    func test_extendStacksButCapsAt48h() {
        let active = now.addingTimeInterval(3600)
        XCTAssertEqual(RewardPass.extended(from: active, now: now), now.addingTimeInterval(3600 + RewardPass.duration))
        let almostFull = now.addingTimeInterval(RewardPass.duration * 2 - 10)
        XCTAssertEqual(RewardPass.extended(from: almostFull, now: now), now.addingTimeInterval(RewardPass.duration * 2))
    }

    func test_persistRoundTrip() {
        let suite = "test.rewardpass.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: suite) }
        XCTAssertNil(RewardPass.load(d))
        RewardPass.save(now, d)
        XCTAssertEqual(RewardPass.load(d), now)
    }
}
