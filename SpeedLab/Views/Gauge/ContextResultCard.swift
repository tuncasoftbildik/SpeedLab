import SwiftUI

/// Sonuç kartı + altında bağlam satırı (ortalamaya göre fark ya da kullanım bandı).
struct ContextResultCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let context: String?
    var contextColor: Color = .npGreen

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.npTextSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.npTextPrimary)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            }
            if let context {
                Text(context)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(contextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 16, tint: color)
    }
}
