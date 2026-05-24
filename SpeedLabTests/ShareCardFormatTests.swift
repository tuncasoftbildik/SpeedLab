import XCTest
@testable import SpeedLab

final class ShareCardFormatTests: XCTestCase {
    func test_pixelSizes() {
        XCTAssertEqual(ShareCardFormat.square.pixelSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(ShareCardFormat.story.pixelSize, CGSize(width: 1080, height: 1920))
    }
    func test_pointSizeIsPixelOverScale() {
        XCTAssertEqual(ShareCardFormat.square.pointSize.width,
                       1080 / ShareCardFormat.renderScale, accuracy: 0.01)
    }
    func test_appStoreURL() {
        XCTAssertEqual(AppStoreLink.url, "https://apps.apple.com/app/id6761667861")
    }
}
