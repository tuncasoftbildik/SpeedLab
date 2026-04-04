import SwiftUI

struct SpeedGaugeView: View {
    let value: Double // 0-1
    let speed: Double // Mbps
    let phase: SpeedTestPhase

    @State private var animatedValue: Double = 0

    var body: some View {
        ZStack {
            // Arka plan ark
            Circle()
                .trim(from: 0.15, to: 0.85)
                .rotation(.degrees(126))
                .stroke(Color.npSurfaceLight, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 240, height: 240)

            // Renkli ark
            Circle()
                .trim(from: 0.15, to: 0.15 + animatedValue * 0.7)
                .rotation(.degrees(126))
                .stroke(
                    AngularGradient(
                        colors: [.npPurple, .npPrimary, .npBlue, .npCyan],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .shadow(color: .npCyan.opacity(0.4), radius: 12)

            // Tick marks
            ForEach(0..<13, id: \.self) { i in
                let angle = 126.0 + Double(i) * (252.0 / 12.0)
                Rectangle()
                    .fill(i % 3 == 0 ? Color.npTextSecondary : Color.npSurfaceLight)
                    .frame(width: i % 3 == 0 ? 2 : 1, height: i % 3 == 0 ? 12 : 8)
                    .offset(y: -108)
                    .rotationEffect(.degrees(angle))
            }

            // Merkez içerik
            VStack(spacing: 4) {
                if phase == .idle {
                    Image(systemName: "play.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient.npMain)
                } else {
                    Text(speed < 1 ? String(format: "%.1f", speed) : String(format: "%.0f", speed))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.npMain)

                    Text("Mbps")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.npTextSecondary)
                }
            }

            // Speed labels
            VStack {
                Spacer()
                HStack {
                    Text("0")
                    Spacer()
                    Text("200+")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.npTextSecondary)
                .padding(.horizontal, 30)
            }
            .frame(width: 260, height: 260)
        }
        .onChange(of: value) { newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedValue = newValue
            }
        }
    }
}
