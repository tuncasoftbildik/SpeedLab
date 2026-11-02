import XCTest
import UIKit
@testable import SpeedLab

@MainActor
final class ShareCardRendererTests: XCTestCase {
    private func sampleResult() -> SpeedTestResult {
        SpeedTestResult(downloadSpeed: 38.2, uploadSpeed: 12.4, ping: 14, jitter: 2,
                        ssid: "Home", isp: "Turknet", ipAddress: "1.2.3.4")
    }

    func test_rendersNonNilAtCorrectPixelSize() {
        for format in ShareCardFormat.allCases {
            let img = ShareCardRenderer.render(result: sampleResult(), format: format)
            guard let img2 = img else { XCTFail("render returned nil for \(format)"); continue }
            XCTAssertEqual(img2.size.width * img2.scale, format.pixelSize.width, accuracy: 1)
            XCTAssertEqual(img2.size.height * img2.scale, format.pixelSize.height, accuracy: 1)
        }
    }

    func test_cardIsNotBlank() throws {
        // Catches the empty-gauge / blank-render failure mode.
        let img = try XCTUnwrap(ShareCardRenderer.render(result: sampleResult(), format: .square))
        let cg = try XCTUnwrap(img.cgImage)
        let w = cg.width, h = cg.height
        var pixels = [UInt32](repeating: 0, count: w * h)
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = try XCTUnwrap(CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8,
                                          bytesPerRow: w * 4, space: cs,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var colors = Set<UInt32>()
        let stepX = max(1, w / 20), stepY = max(1, h / 20)
        for y in stride(from: 0, to: h, by: stepY) {
            for x in stride(from: 0, to: w, by: stepX) {
                colors.insert(pixels[y * w + x])
            }
        }
        XCTAssertGreaterThan(colors.count, 3, "card looks blank — gauge/content not rendered")
    }
}

extension ShareCardRendererTests {
    /// Gözle inceleme: yeni küçük logo ile paylaşım kartını /tmp'ye yazar.
    func test_renderSampleCardForReview() throws {
        let r = SpeedTestResult(downloadSpeed: 85.5, uploadSpeed: 20.1, ping: 23, jitter: 4.1, ssid: "Ev", isp: "Turknet", ipAddress: "1.2.3.4")
        let image = try XCTUnwrap(ShareCardRenderer.render(result: r, format: .square))
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/speedlab-sharecard.png"))
    }
}
