import SwiftUI

struct ShareGaugeView: View {
    let value: Double      // 0...1 normalized speed
    let speed: Double      // Mbps
    var diameter: CGFloat = 240

    private var clamped: Double { min(max(value, 0), 1) }
    private var k: CGFloat { diameter / 240 }  // scale factor vs. the 240pt reference

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0.15, to: 0.85)
                .rotation(.degrees(126))
                .stroke(Color.npBrandSurfaceLight, style: StrokeStyle(lineWidth: 20 * k, lineCap: .round))
                .frame(width: diameter, height: diameter)

            // Value arc (static — drawn directly at `clamped`, orange→cyan)
            Circle()
                .trim(from: 0.15, to: 0.15 + clamped * 0.7)
                .rotation(.degrees(126))
                .stroke(
                    AngularGradient(
                        colors: [.npOrange, .npPrimary, .npCyan],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20 * k, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .npCyan.opacity(0.4), radius: 12 * k)

            // Ticks
            ForEach(0..<13, id: \.self) { i in
                let angle = 126.0 + Double(i) * (252.0 / 12.0)
                Rectangle()
                    .fill(i % 3 == 0 ? Color.npBrandTextSecondary : Color.npBrandSurfaceLight)
                    .frame(width: (i % 3 == 0 ? 2 : 1) * k, height: (i % 3 == 0 ? 12 : 8) * k)
                    .offset(y: -108 * k)
                    .rotationEffect(.degrees(angle))
            }

            // Center value
            VStack(spacing: 4 * k) {
                Text(speed < 1 ? String(format: "%.1f", speed) : String(format: "%.0f", speed))
                    .font(.system(size: 56 * k, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.npMain)
                Text("Mbps ↓")
                    .font(.system(size: 14 * k, weight: .semibold))
                    .foregroundColor(.npBrandTextSecondary)
            }
        }
        .frame(width: diameter + 24 * k, height: diameter + 24 * k)
    }
}

#Preview {
    ZStack {
        Color.npBrandBackground
        ShareGaugeView(value: 0.19, speed: 38.2, diameter: 460)
    }
}
