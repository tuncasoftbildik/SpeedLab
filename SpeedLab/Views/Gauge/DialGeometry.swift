import SwiftUI

/// 270° kadran geometrisi: 12'den saat yönüne −135°'de başlar, +135°'de biter (taslak: start −135, sweep 270).
struct DialGeometry {
    let center: CGPoint
    let radius: CGFloat

    static let startDeg: Double = -135
    static let sweepDeg: Double = 270

    /// 12 yönü 0°, saat yönü pozitif.
    func angle(fraction: Double) -> Angle {
        .degrees(Self.startDeg + min(max(fraction, 0), 1) * Self.sweepDeg)
    }

    func point(fraction: Double, radius r: CGFloat) -> CGPoint {
        let rad = angle(fraction: fraction).radians
        return CGPoint(x: center.x + r * CGFloat(sin(rad)), y: center.y - r * CGFloat(cos(rad)))
    }

    /// `from`→`to` kesri arası yay (saat yönü).
    func arc(from f0: Double, to f1: Double, radius r: CGFloat) -> Path {
        var p = Path()
        let a0 = angle(fraction: f0).radians - .pi / 2
        let a1 = angle(fraction: f1).radians - .pi / 2
        p.addArc(center: center, radius: r, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
        return p
    }
}
