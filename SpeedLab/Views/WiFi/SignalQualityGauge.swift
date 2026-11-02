import SwiftUI

/// 180° yarım kadran: sinyal kalitesi yüzdesi; nil'de soluk ve "Ölçülemiyor".
struct SignalQualityGauge: View {
    let quality: Double?
    @StateObject private var loc = LocalizationService.shared

    private var fraction: Double { min(max(quality ?? 0, 0), 1) }
    private var available: Bool { (quality ?? 0) > 0 }

    private var tint: Color {
        switch fraction {
        case ..<0.3: return .npRed
        case ..<0.55: return .npOrange
        case ..<0.8: return .npGreen
        default: return .npCyan
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Canvas { ctx, size in
                    let r: CGFloat = size.width / 2 - 12
                    let c = CGPoint(x: size.width / 2, y: size.height - 8)
                    func arc(_ f0: Double, _ f1: Double) -> Path {
                        var p = Path()
                        p.addArc(center: c, radius: r, startAngle: .degrees(180 + 180 * f0), endAngle: .degrees(180 + 180 * f1), clockwise: false)
                        return p
                    }
                    ctx.stroke(arc(0, 1), with: .color(Color.npTextSecondary.opacity(0.22)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    if available {
                        let g = Gradient(colors: [.npRed, .npOrange, .npGreen, .npCyan])
                        var glow = ctx; glow.addFilter(.blur(radius: 8)); glow.opacity = 0.5
                        glow.stroke(arc(0, fraction), with: .linearGradient(g, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: 0)),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        ctx.stroke(arc(0, fraction), with: .linearGradient(g, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: 0)),
                                   style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    }
                    for i in 0...20 {
                        let f = Double(i) / 20
                        let a = (180 + 180 * f) * .pi / 180
                        let p0 = CGPoint(x: c.x + (r - 20) * cos(a), y: c.y + (r - 20) * sin(a))
                        let p1 = CGPoint(x: c.x + (r - (i % 5 == 0 ? 32 : 26)) * cos(a), y: c.y + (r - (i % 5 == 0 ? 32 : 26)) * sin(a))
                        var t = Path(); t.move(to: p0); t.addLine(to: p1)
                        ctx.stroke(t, with: .color(available && f <= fraction ? tint.opacity(0.9) : Color.npTextSecondary.opacity(0.35)),
                                   style: StrokeStyle(lineWidth: i % 5 == 0 ? 2.2 : 1.2, lineCap: .round))
                    }
                }
                .frame(width: 240, height: 130)

                VStack(spacing: 0) {
                    if let p = SignalQuality.percent(quality) {
                        Text("%\(p)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.npTextPrimary)
                            .contentTransition(.numericText())
                    } else {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 28))
                            .foregroundColor(.npTextSecondary)
                    }
                }
                .offset(y: 28)
            }
            Text(loc.t(SignalQuality.bandKey(quality)))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(available ? tint : .npTextSecondary)
        }
    }
}
