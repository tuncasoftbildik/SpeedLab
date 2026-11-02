import SwiftUI

/// Kokpit kadranı (A taslağı): 270° logaritmik skala, parlayan dolum ve ibre, altta büyük rakam.
struct DialGaugeView: View {
    let speed: Double
    let phase: SpeedTestPhase
    let isUploading: Bool
    let idleTitle: String

    static let width: CGFloat = 300
    static let height: CGFloat = 270

    @State private var animated: Double = 0

    private var isIdle: Bool { phase == .idle }

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: !isIdle)) { timeline in
                let breath = isIdle ? 0.5 + 0.5 * sin(timeline.date.timeIntervalSinceReferenceDate * .pi) : 1
                Canvas(rendersAsynchronously: false) { ctx, size in
                    draw(in: &ctx, size: size, breath: breath)
                }
            }
            .frame(width: Self.width, height: Self.height)

            VStack(spacing: 2) {
                if isIdle {
                    Text(idleTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.npTextPrimary)
                } else {
                    Text(formatted(speed))
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.npTextPrimary)
                        .contentTransition(.numericText())
                    Text("MBPS")
                        .font(.system(size: 13, weight: .semibold))
                        .kerning(2)
                        .foregroundColor(.npTextSecondary)
                }
            }
            .offset(y: Self.height * 0.34)
        }
        .frame(width: Self.width, height: Self.height)
        .onChange(of: speed) { s in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { animated = GaugeScale.fraction(s) }
        }
        .onChange(of: phase) { p in
            if p == .idle || p == .testingUpload || p == .preparingUpload {
                withAnimation(.easeInOut(duration: 0.5)) { animated = p == .idle ? 0 : GaugeScale.fraction(speed) }
            }
        }
        .onAppear { animated = GaugeScale.fraction(speed) }
    }

    private func formatted(_ v: Double) -> String {
        v < 10 ? String(format: "%.1f", v) : String(format: "%.0f", v)
    }

    // MARK: - Çizim

    private func draw(in ctx: inout GraphicsContext, size: CGSize, breath: Double) {
        let r: CGFloat = 128
        let geo = DialGeometry(center: CGPoint(x: size.width / 2, y: r + 10), radius: r)
        let fill = max(0, min(animated, 1))
        let railWidth: CGFloat = 14
        let gradient = Gradient(colors: isUploading
            ? [.npPurple, .npPrimary, .npCyan]
            : [.npGradientStart, .npGradientMid, .npGradientEnd])
        let shading = GraphicsContext.Shading.linearGradient(gradient,
            startPoint: CGPoint(x: 0, y: size.height), endPoint: CGPoint(x: size.width, y: 0))

        // Arka ray
        ctx.stroke(geo.arc(from: 0, to: 1, radius: r), with: .color(Color.npTextSecondary.opacity(isIdle ? 0.22 + 0.10 * breath : 0.24)),
                   style: StrokeStyle(lineWidth: railWidth, lineCap: .round))
        // İnce iç çizgi
        ctx.stroke(geo.arc(from: 0, to: 1, radius: r - 18), with: .color(Color.npTextSecondary.opacity(0.25)), lineWidth: 1)

        if fill > 0.002 {
            // Yumuşak parıltı (dış katman)
            var glow = ctx
            glow.addFilter(.blur(radius: 10))
            glow.opacity = 0.45
            glow.stroke(geo.arc(from: 0, to: fill, radius: r), with: shading, style: StrokeStyle(lineWidth: railWidth, lineCap: .round))
            // Dolum
            ctx.stroke(geo.arc(from: 0, to: fill, radius: r), with: shading, style: StrokeStyle(lineWidth: railWidth, lineCap: .round))
            // Beyaza parlayan uç (son %6)
            var tip = ctx
            tip.addFilter(.blur(radius: 4))
            tip.opacity = 0.9
            tip.stroke(geo.arc(from: max(0, fill - 0.06), to: fill, radius: r), with: .color(.white),
                       style: StrokeStyle(lineWidth: railWidth, lineCap: .round))
        }

        // Tikler
        for i in 0...60 {
            let f = Double(i) / 60
            let major = i % 10 == 0
            let p0 = geo.point(fraction: f, radius: r - 24)
            let p1 = geo.point(fraction: f, radius: r - (major ? 38 : 32))
            var path = Path(); path.move(to: p0); path.addLine(to: p1)
            let lit = f <= fill
            ctx.stroke(path, with: .color(lit ? Color.npCyan.opacity(0.95) : Color.npTextSecondary.opacity(0.45)),
                       style: StrokeStyle(lineWidth: major ? 2.5 : 1.2, lineCap: .round))
        }

        // Etiketler
        for value in GaugeScale.labels {
            let f = GaugeScale.fraction(value)
            let p = geo.point(fraction: f, radius: r - 54)
            let lit = f <= fill + 0.0001
            let text = Text(GaugeScale.label(value))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(lit ? .npTextPrimary : .npTextSecondary)
            ctx.draw(ctx.resolve(text), at: p, anchor: .center)
        }

        // İbre
        if !isIdle || fill > 0 {
            let tipPoint = geo.point(fraction: fill, radius: r - 28)
            var needle = Path(); needle.move(to: geo.center); needle.addLine(to: tipPoint)
            var nGlow = ctx
            nGlow.addFilter(.blur(radius: 6))
            nGlow.opacity = 0.6
            nGlow.stroke(needle, with: .color(.npCyan), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            ctx.stroke(needle, with: .color(.white), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }

        // Göbek
        let hub = Path(ellipseIn: CGRect(x: geo.center.x - 10, y: geo.center.y - 10, width: 20, height: 20))
        ctx.fill(hub, with: .color(.npBackground))
        ctx.stroke(hub, with: .color(.npCyan), lineWidth: 2.5)
        ctx.fill(Path(ellipseIn: CGRect(x: geo.center.x - 3, y: geo.center.y - 3, width: 6, height: 6)), with: .color(.npCyan))
    }
}
