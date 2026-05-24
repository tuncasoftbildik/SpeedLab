import XCTest
@testable import SpeedLab

final class QRCodeGeneratorTests: XCTestCase {
    func test_validURLProducesImage() {
        XCTAssertNotNil(QRCodeGenerator.generate(from: AppStoreLink.url))
    }
    func test_emptyStringReturnsNil() {
        XCTAssertNil(QRCodeGenerator.generate(from: ""))
    }
}
