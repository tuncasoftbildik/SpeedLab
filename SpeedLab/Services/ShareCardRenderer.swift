import SwiftUI
import UIKit

@MainActor
enum ShareCardRenderer {
    static func render(result: SpeedTestResult, format: ShareCardFormat) -> UIImage? {
        let view = ShareCardView(result: result, format: format)
        let renderer = ImageRenderer(content: view)
        renderer.scale = ShareCardFormat.renderScale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
