import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // Ad Unit IDs
    static let bannerAdUnitID = "ca-app-pub-3770969986981001/3125134660"
    static let interstitialAdUnitID = "ca-app-pub-3770969986981001/6092312428"
    /// "Rewarded - Pro 24h" (4 Kas 2026)
    static let rewardedAdUnitID = "ca-app-pub-3770969986981001/9130251024"

    @Published var interstitialReady = false
    private var interstitialAd: GADInterstitialAd?
    @Published var rewardedReady = false
    private var rewardedAd: GADRewardedAd?
    private var rewardedLoading = false

    override init() {
        super.init()
    }

    func configure() {
        GADMobileAds.sharedInstance().start { _ in }
    }

    // MARK: - Interstitial

    func loadInterstitial() {
        GADInterstitialAd.load(
            withAdUnitID: Self.interstitialAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor in
                if let ad {
                    self?.interstitialAd = ad
                    self?.interstitialReady = true
                }
            }
        }
    }

    /// Her testten sonra interstitial göster (Pro hariç)
    func showInterstitialIfNeeded() {
        guard !SharedStore().isPro() else { return }
        guard let ad = interstitialAd else {
            loadInterstitial()
            return
        }

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            ad.present(fromRootViewController: root)
        }

        interstitialAd = nil
        interstitialReady = false
        loadInterstitial()
    }

    // MARK: - Rewarded

    func loadRewarded() {
        guard rewardedAd == nil, !rewardedLoading else { return }
        rewardedLoading = true
        GADRewardedAd.load(withAdUnitID: Self.rewardedAdUnitID, request: GADRequest()) { [weak self] ad, _ in
            Task { @MainActor in
                self?.rewardedLoading = false
                if let ad {
                    self?.rewardedAd = ad
                    self?.rewardedReady = true
                }
            }
        }
    }

    /// Ödüllü reklamı gösterir; kullanıcı ödülü hak ederse `completion(true)`.
    /// Reklam hazır değilse `completion(false)` döner ve yeniden yüklenir (ödül verilmez).
    func showRewarded(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd,
              let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController ?? scene.windows.first?.rootViewController else {
            loadRewarded()
            completion(false)
            return
        }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        rewardedAd = nil
        rewardedReady = false
        var earned = false
        let delegate = RewardedDelegate { [weak self] in
            completion(earned)
            self?.loadRewarded()
        }
        rewardedDelegate = delegate
        ad.fullScreenContentDelegate = delegate
        ad.present(fromRootViewController: top) { earned = true }
    }

    private var rewardedDelegate: RewardedDelegate?
}

/// Reklam kapanınca (ya da gösterilemeyince) tek sefer haber verir.
private final class RewardedDelegate: NSObject, GADFullScreenContentDelegate {
    private var done: (() -> Void)?
    init(done: @escaping () -> Void) { self.done = done }
    private func finish() { let d = done; done = nil; d?() }
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) { finish() }
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { finish() }
}
