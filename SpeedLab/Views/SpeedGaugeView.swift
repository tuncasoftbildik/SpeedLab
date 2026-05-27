import SwiftUI

struct SpeedGaugeView: View {
    let value: Double // 0-1 (uyumluluk için; yay log-skala ile speed'ten hesaplanır)
    let speed: Double // Mbps
    let phase: SpeedTestPhase

    @State private var animatedFraction: Double = 0

    // Ookla benzeri logaritmik skala (eşit açı dilimleri, dilim içi lineer)
    private let ticks: [Double] = [0, 5, 10, 50, 100, 250, 500, 750, 1000]
    private let gaugeSize: CGFloat = 250
    private let arcTrim: Double = 0.75        // dairenin %75'i = 270°
    private let pathRotation: Double = 135    // yay başlangıcı sol-alt
    private let startAngle: Double = 225      // ibre/etiket: tepeden saat yönü derece
    private let sweepAngle: Double = 270

    private func fraction(for s: Double) -> Double {
        guard s > 0 else { return 0 }
        if s >= ticks.last! { return 1 }
        for i in 0..<(ticks.count - 1) where s < ticks[i + 1] {
            let seg = (s - ticks[i]) / (ticks[i + 1] - ticks[i])
            return (Double(i) + seg) / Double(ticks.count - 1)
        }
        return 1
    }

    private func tickLabel(_ t: Double) -> String {
        t >= 1000 ? "1k" : String(format: "%.0f", t)
    }

    var body: some View {
        ZStack {
            // Arka plan yay
            Circle()
                .trim(from: 0, to: arcTrim)
                .rotation(.degrees(pathRotation))
                .stroke(Color.npSurfaceLight, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: gaugeSize, height: gaugeSize)

            // Renkli ilerleme yayı
            Circle()
                .trim(from: 0, to: arcTrim * animatedFraction)
                .rotation(.degrees(pathRotation))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.npCyan, .npBlue, .npPurple]),
                        center: .center,
                        startAngle: .degrees(pathRotation),
                        endAngle: .degrees(pathRotation + sweepAngle)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: gaugeSize, height: gaugeSize)
                .shadow(color: .npCyan.opacity(0.5), radius: 8)

            // Skala etiketleri
            ForEach(Array(ticks.enumerated()), id: \.offset) { i, t in
                let f = Double(i) / Double(ticks.count - 1)
                let rad = (startAngle + f * sweepAngle) * .pi / 180
                let r = gaugeSize / 2 - 30
                Text(tickLabel(t))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.npTextSecondary)
                    .position(
                        x: gaugeSize / 2 + r * sin(rad),
                        y: gaugeSize / 2 - r * cos(rad)
                    )
            }
            .frame(width: gaugeSize, height: gaugeSize)

            // İbre
            NeedleShape()
                .fill(LinearGradient(colors: [.white, .npCyan], startPoint: .top, endPoint: .bottom))
                .frame(width: gaugeSize, height: gaugeSize)
                .rotationEffect(.degrees(startAngle + animatedFraction * sweepAngle))
                .shadow(color: .npCyan.opacity(0.6), radius: 4)

            // Merkez göbek
            Circle()
                .fill(Color.npSurface)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.npCyan.opacity(0.5), lineWidth: 2))

            // Alt boşlukta sayı / play
            VStack(spacing: 2) {
                if phase == .idle {
                    Image(systemName: "play.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(LinearGradient.npMain)
                } else {
                    Text(speed < 1 ? String(format: "%.1f", speed) : String(format: "%.0f", speed))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.npMain)
                    Text("Mbps")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.npTextSecondary)
                }
            }
            .offset(y: gaugeSize * 0.20)
        }
        .frame(width: gaugeSize, height: gaugeSize)
        .onChange(of: speed) { newSpeed in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                animatedFraction = fraction(for: newSpeed)
            }
        }
        .onChange(of: phase) { newPhase in
            if newPhase == .idle {
                withAnimation(.easeInOut(duration: 0.3)) { animatedFraction = 0 }
            }
        }
    }
}

// Merkezde pivotlanan, yukarı bakan üçgen ibre (gaugeSize'lık kareye çizilir).
struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let tipY = rect.minY + 30        // uç, yayın hemen içinde
        let baseHalf: CGFloat = 6
        var p = Path()
        p.move(to: CGPoint(x: cx, y: tipY))
        p.addLine(to: CGPoint(x: cx - baseHalf, y: cy))
        p.addLine(to: CGPoint(x: cx + baseHalf, y: cy))
        p.closeSubpath()
        return p
    }
}
