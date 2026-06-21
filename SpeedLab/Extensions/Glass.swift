import SwiftUI

// MARK: - Aurora Background
/// Koyu zemin üzerine yumuşak, hafif animasyonlu renk lekeleri.
/// Glassmorphism'in çalışması için camın "kıracağı" renkli derinlik sağlar.
struct AuroraBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.npBackground

            blob(color: .npCyan, size: 320, opacity: 0.38,
                 from: CGSize(width: -110, height: -260),
                 to: CGSize(width: -150, height: -210))

            blob(color: .npPurple, size: 300, opacity: 0.32,
                 from: CGSize(width: 150, height: -30),
                 to: CGSize(width: 110, height: 30))

            blob(color: .npBlue, size: 300, opacity: 0.28,
                 from: CGSize(width: -120, height: 270),
                 to: CGSize(width: -80, height: 230))
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func blob(color: Color, size: CGFloat, opacity: Double,
                      from: CGSize, to: CGSize) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 110)
            .opacity(opacity)
            .offset(animate ? to : from)
    }
}

// MARK: - Glass Card
/// Yarı saydam materyal kart: arka aurora'yı bulanıklaştırır, ince ışık kenarı + yumuşak gölge.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [tint.opacity(0.28), tint.opacity(0.06)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [(tint ?? .white).opacity(0.40), .white.opacity(0.05), .clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, tint: Color? = nil) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, tint: tint))
    }
}
