import SwiftUI

struct ShareGaugeView: View {
    let value: Double   // 0...1 normalized speed
    let speed: Double   // Mbps

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0.15, to: 0.85)
                .rotation(.degrees(126))
                .stroke(Color.npSurfaceLight, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 240, height: 240)

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
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .shadow(color: .npCyan.opacity(0.4), radius: 12)

            // Ticks
            ForEach(0..<13, id: \.self) { i in
                let angle = 126.0 + Double(i) * (252.0 / 12.0)
                Rectangle()
                    .fill(i % 3 == 0 ? Color.npTextSecondary : Color.npSurfaceLight)
                    .frame(width: i % 3 == 0 ? 2 : 1, height: i % 3 == 0 ? 12 : 8)
                    .offset(y: -108)
                    .rotationEffect(.degrees(angle))
            }

            // Center value
            VStack(spacing: 4) {
                Text(speed < 1 ? String(format: "%.1f", speed) : String(format: "%.0f", speed))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.npMain)
                Text("Mbps ↓")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.npTextSecondary)
            }
        }
        .frame(width: 260, height: 260)
    }
}

#Preview {
    ZStack {
        Color.npBackground
        ShareGaugeView(value: 0.19, speed: 38.2)
    }
}
