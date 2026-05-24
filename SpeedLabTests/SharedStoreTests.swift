import XCTest
@testable import SpeedLab

final class SharedStoreTests: XCTestCase {
    private func tempStore() -> SharedStore {
        let suite = "test.sharedstore.\(UUID().uuidString)"
        return SharedStore(defaults: UserDefaults(suiteName: suite)!)
    }

    func test_snapshotRoundTrip() {
        let store = tempStore()
        let snap = WidgetSnapshot(download: 38.2, upload: 12.4, ping: 14, jitter: 2, isp: "Turknet", date: Date(timeIntervalSince1970: 1_000_000))
        store.save(snap)
        XCTAssertEqual(store.loadSnapshot(), snap)
    }

    func test_emptyByDefault() {
        XCTAssertNil(tempStore().loadSnapshot())
    }

    func test_proFlag() {
        let store = tempStore()
        XCTAssertFalse(store.isPro())
        store.setPro(true)
        XCTAssertTrue(store.isPro())
    }

    func test_recentDownloads() {
        let store = tempStore()
        store.saveRecent([35, 41, 29])
        XCTAssertEqual(store.recentDownloads(), [35, 41, 29])
    }
}
