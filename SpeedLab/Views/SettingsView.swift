import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var storeVM: StoreViewModel
    @StateObject private var loc = LocalizationService.shared
    @State private var showProSheet = false

    var body: some View {
        ZStack {
            Color.npBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text(loc.t("settings"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Pro banner
                    if !storeVM.isPro {
                        Button { showProSheet = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.npOrange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loc.t("upgrade_pro"))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(loc.t("feature_no_ads") + " • " + loc.t("feature_unlimited_history"))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.npTextSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.npTextSecondary)
                            }
                            .padding(16)
                            .background(
                                LinearGradient(colors: [Color.npOrange.opacity(0.15), Color.npOrange.opacity(0.05)],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.npOrange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.npGreen)
                            Text("Pro")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.npGreen)
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.npGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                    }

                    // Language
                    VStack(spacing: 0) {
                        SettingsSectionHeader(title: loc.t("language"))
                        ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                            Button {
                                withAnimation { loc.language = lang }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(lang.flag)
                                        .font(.system(size: 22))
                                    Text(lang.displayName)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if loc.language == lang {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.npCyan)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            if lang != AppLanguage.allCases.last {
                                Divider().background(Color.npBorder).padding(.leading, 54)
                            }
                        }
                    }
                    .background(Color.npSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // General
                    VStack(spacing: 0) {
                        SettingsSectionHeader(title: loc.t("about"))

                        if !storeVM.isPro {
                            SettingsButton(icon: "arrow.clockwise", label: loc.t("restore_purchases"), color: .npBlue) {
                                Task { await storeVM.restorePurchases() }
                            }
                            Divider().background(Color.npBorder).padding(.leading, 54)
                        }

                        SettingsButton(icon: "star.fill", label: loc.t("rate_app"), color: .npOrange) {
                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                SKStoreReviewController.requestReview(in: scene)
                            }
                        }
                        Divider().background(Color.npBorder).padding(.leading, 54)

                        SettingsButton(icon: "lock.shield.fill", label: loc.t("privacy_policy"), color: .npGreen) {
                            // Privacy policy URL
                        }
                        Divider().background(Color.npBorder).padding(.leading, 54)

                        SettingsButton(icon: "doc.text.fill", label: loc.t("terms"), color: .npPurple) {
                            // Terms URL
                        }
                    }
                    .background(Color.npSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // Footer
                    VStack(spacing: 4) {
                        Text("SpeedLab v1.0.0")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.npTextSecondary)
                        Text(loc.t("made_by"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.npTextSecondary.opacity(0.6))
                    }
                    .padding(.top, 12)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showProSheet) {
            ProUpgradeSheet()
        }
    }
}

struct SettingsSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.npTextSecondary)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

struct SettingsButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.npTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Pro Upgrade Sheet
struct ProUpgradeSheet: View {
    @EnvironmentObject var storeVM: StoreViewModel
    @StateObject private var loc = LocalizationService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.npBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                // Close button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.npTextSecondary)
                    }
                }
                .padding(.horizontal, 20)

                // Crown
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.npOrange, .yellow],
                                       startPoint: .top, endPoint: .bottom)
                    )

                Text("SpeedLab Pro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    ProFeatureRow(icon: "eye.slash.fill", text: loc.t("feature_no_ads"), color: .npCyan)
                    ProFeatureRow(icon: "infinity", text: loc.t("feature_unlimited_history"), color: .npPurple)
                    ProFeatureRow(icon: "map.fill", text: loc.t("feature_wifi_map"), color: .npGreen)
                    ProFeatureRow(icon: "square.and.arrow.up.fill", text: loc.t("feature_export"), color: .npBlue)
                    ProFeatureRow(icon: "rectangle.on.rectangle.fill", text: loc.t("feature_widget"), color: .npOrange)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Purchase buttons
                VStack(spacing: 10) {
                    if storeVM.products.isEmpty {
                        // Fallback when products haven't loaded yet
                        VStack(spacing: 10) {
                            ProPlaceholderButton(title: loc.t("monthly"), highlighted: false)
                            ProPlaceholderButton(title: loc.t("yearly"), highlighted: true)
                        }
                        if storeVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 4)
                        } else {
                            Button {
                                Task { await storeVM.loadProducts() }
                            } label: {
                                Text("Tekrar dene")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.npCyan)
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        ForEach(storeVM.products, id: \.id) { product in
                            Button {
                                Task { let _ = await storeVM.purchase(product) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.subscription?.subscriptionPeriod.unit == .month ? loc.t("monthly") : loc.t("yearly"))
                                            .font(.system(size: 15, weight: .bold))
                                        if product.subscription?.subscriptionPeriod.unit == .year {
                                            Text("En avantajlı")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.npGreen)
                                        }
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.system(size: 17, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    product.subscription?.subscriptionPeriod.unit == .year
                                    ? AnyShapeStyle(LinearGradient.npButton)
                                    : AnyShapeStyle(Color.npSurface)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }

                    // Auto-renew disclosure (Apple 3.1.2 zorunlu)
                    Text("Abonelik otomatik olarak yenilenir. Mevcut dönem bitiminden en az 24 saat önce iptal edilmediği takdirde Apple ID hesabınızdan ücret tahsil edilir. Aboneliği istediğiniz zaman App Store hesap ayarlarından yönetebilir veya iptal edebilirsiniz.")
                        .font(.system(size: 10))
                        .foregroundColor(.npTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .padding(.top, 6)

                    // Terms & Privacy links (Apple 5.1.1/5.1.2 zorunlu)
                    HStack(spacing: 16) {
                        Link("Kullanım Şartları", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.npCyan)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.npTextSecondary)

                        Link("Gizlilik Politikası", destination: URL(string: "https://bot.tuncabildik.online/privacy/speedlab.html")!)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.npCyan)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.npTextSecondary)

                        Button {
                            Task { await storeVM.restorePurchases() }
                        } label: {
                            Text(loc.t("restore_purchases"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.npCyan)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .task { await storeVM.loadProducts() }
    }
}

struct ProPlaceholderButton: View {
    let title: String
    let highlighted: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                if highlighted {
                    Text("En avantajlı")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.npGreen)
                }
            }
            Spacer()
            Text("—")
                .font(.system(size: 17, weight: .bold))
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(16)
        .background(
            highlighted
            ? AnyShapeStyle(LinearGradient.npButton.opacity(0.5))
            : AnyShapeStyle(Color.npSurface)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
