import SwiftUI

/// Kokpit kadranı (A taslağı): 270° logaritmik skala, parlayan dolum ve ibre, altta büyük rakam.
/// İki katman: statik (ray, tikler, etiketler — yalnız tema değişince çizilir) ve dinamik (dolum, ibre, yanan tikler).
struct DialGaugeView: View {
    let speed: Double
    let phase: SpeedTestPhase
    let isUploading: Bool
    let idleTitle: String

    static let width: CGFloat = 300
    static let height: CGFloat = 270
    static let radius: CGFloat = 128
    static let railWidth: CGFloat = 14

    @Environment(\.colorScheme) private var scheme
    @State private var animated: Double = 0
    @State private var breathing = false

    private var isIdle: Bool { phase == .idle }
    private var geo: DialGeometry {
        DialGeometry(center: CGPoint(x: Self.width / 2, y: Self.radius + 10), radius: Self.radius)
    }

    var body: some View {
        ZStack {
            // Statik katman: tema dışında hiçbir şeye bağlı değil → kare başına çizilmez.
            Canvas(rendersAsynchronously: true) { ctx, _ in drawStatic(in: &ctx) }
                .frame(width: Self.width, height: Self.height)

            // Boşta nefes alan ray (SwiftUI animasyonu, Canvas yeniden çizimi yok)
            if isIdle {
                DialArcShape(geo: geo, from: 0, to: 1)
                    .stroke(Color.npTextSecondary.opacity(0.12), style: StrokeStyle(lineWidth: Self.railWidth, lineCap: .round))
                    .frame(width: Self.width, height: Self.height)
                    .opacity(breathing ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: breathing)
                    .onAppear { breathing = true }
                    .onDisappear { breathing = false }
            }

            // Dinamik katman: yalnız `animated` değişince
            Canvas(rendersAsynchronously: false) { ctx, size in drawDynamic(in: &ctx, size: size) }
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

    // MARK: - Statik katman

    private func drawStatic(in ctx: inout GraphicsContext) {
        let r = Self.radius
        ctx.stroke(geo.arc(from: 0, to: 1, radius: r), with: .color(Color.npTextSecondary.opacity(0.24)),
                   style: StrokeStyle(lineWidth: Self.railWidth, lineCap: .round))
        ctx.stroke(geo.arc(from: 0, to: 1, radius: r - 18), with: .color(Color.npTextSecondary.opacity(0.25)), lineWidth: 1)
        for i in 0...60 {
            let f = Double(i) / 60
            let major = i % 10 == 0
            ctx.stroke(tickPath(f, major: major), with: .color(Color.npTextSecondary.opacity(0.45)),
                       style: StrokeStyle(lineWidth: major ? 2.5 : 1.2, lineCap: .round))
        }
        for value in GaugeScale.labels {
            let p = geo.point(fraction: GaugeScale.fraction(value), radius: r - 54)
            let text = Text(GaugeScale.label(value))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.npTextSecondary)
            ctx.draw(ctx.resolve(text), at: p, anchor: .center)
        }
    }

    // MARK: - Dinamik katman

    private func drawDynamic(in ctx: inout GraphicsContext, size: CGSize) {
        let r = Self.radius
        let fill = max(0, min(animated, 1))
        let gradient = Gradient(colors: isUploading
            ? [.npPurple, .npPrimary, .npCyan]
            : [.npGradientStart, .npGradientMid, .npGradientEnd])
        let shading = GraphicsContext.Shading.linearGradient(gradient,
            startPoint: CGPoint(x: 0, y: size.height), endPoint: CGPoint(x: size.width, y: 0))
        // Uç mavi dolumun üstünde olduğu için her temada beyaz; ibre açık zeminde koyu metin rengi.
        let hot: Color = .white
        let needleColor: Color = scheme == .dark ? .white : .npTextPrimary

        if fill > 0.002 {
            var glow = ctx
            glow.addFilter(.blur(radius: 10))
            glow.opacity = 0.45
            glow.stroke(geo.arc(from: 0, to: fill, radius: r), with: shading, style: StrokeStyle(lineWidth: Self.railWidth, lineCap: .round))
            ctx.stroke(geo.arc(from: 0, to: fill, radius: r), with: shading, style: StrokeStyle(lineWidth: Self.railWidth, lineCap: .round))
            var tip = ctx
            tip.addFilter(.blur(radius: 4))
            tip.opacity = 0.9
            tip.stroke(geo.arc(from: max(0, fill - 0.06), to: fill, radius: r), with: .color(hot),
                       style: StrokeStyle(lineWidth: Self.railWidth, lineCap: .round))
        }

        // Yanan tikler ve etiketler (yalnız dolumun gerisindekiler)
        let litCount = Int((fill * 60).rounded(.down))
        if litCount >= 0 {
            for i in 0...min(litCount, 60) where fill > 0 {
                let major = i % 10 == 0
                ctx.stroke(tickPath(Double(i) / 60, major: major), with: .color(Color.npCyan.opacity(0.95)),
                           style: StrokeStyle(lineWidth: major ? 2.5 : 1.2, lineCap: .round))
            }
        }
        for value in GaugeScale.labels where GaugeScale.fraction(value) <= fill + 0.0001 && fill > 0 {
            let p = geo.point(fraction: GaugeScale.fraction(value), radius: r - 54)
            let text = Text(GaugeScale.label(value))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.npTextPrimary)
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
            ctx.stroke(needle, with: .color(needleColor), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }

        // Göbek
        let hub = Path(ellipseIn: CGRect(x: geo.center.x - 10, y: geo.center.y - 10, width: 20, height: 20))
        ctx.fill(hub, with: .color(.npBackground))
        ctx.stroke(hub, with: .color(.npCyan), lineWidth: 2.5)
        ctx.fill(Path(ellipseIn: CGRect(x: geo.center.x - 3, y: geo.center.y - 3, width: 6, height: 6)), with: .color(.npCyan))
    }

    private func tickPath(_ f: Double, major: Bool) -> Path {
        let r = Self.radius
        let p0 = geo.point(fraction: f, radius: r - 24)
        let p1 = geo.point(fraction: f, radius: r - (major ? 38 : 32))
        var path = Path(); path.move(to: p0); path.addLine(to: p1)
        return path
    }
}

/// `DialGeometry` yayını SwiftUI Shape olarak verir (nefes efekti için).
struct DialArcShape: Shape {
    let geo: DialGeometry
    let from: Double
    let to: Double
    func path(in rect: CGRect) -> Path { geo.arc(from: from, to: to, radius: geo.radius) }
}
