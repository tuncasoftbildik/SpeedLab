import CoreGraphics

enum AppStoreLink {
    static let url = "https://apps.apple.com/app/id6761667861"
}

enum ShareCardFormat: String, CaseIterable, Identifiable {
    case square
    case story

    var id: String { rawValue }

    /// Final rasterized image size in pixels.
    var pixelSize: CGSize {
        switch self {
        case .square: return CGSize(width: 1080, height: 1080)
        case .story:  return CGSize(width: 1080, height: 1920)
        }
    }

    /// SwiftUI layout size in points (rendered at `renderScale`).
    var pointSize: CGSize {
        CGSize(width: pixelSize.width / Self.renderScale,
               height: pixelSize.height / Self.renderScale)
    }

    static let renderScale: CGFloat = 1
}
