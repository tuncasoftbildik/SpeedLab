import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // Ad Unit IDs
    static let bannerAdUnitID = "ca-app-pub-3770969986981001/3125134660"
    static let interstitialAdUnitID = "ca-app-pub-3770969986981001/6092312428"
    static let rewardedAdUnitID = "ca-app-pub-3770969986981001/6681236299"

    @Published var interstitialReady = false
    @Published var rewardedReady = false
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    private var testCount = 0
    private var rewardCompletion: ((Bool) -> Void)?

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

    /// Her 3 testte 1 interstitial göster
    func showInterstitialIfNeeded() {
        testCount += 1
        guard testCount % 3 == 0 else { return }
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
        GADRewardedAd.load(
            withAdUnitID: Self.rewardedAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor in
                if let ad {
                    self?.rewardedAd = ad
                    self?.rewardedReady = true
                }
            }
        }
    }

    /// Ödüllü reklam göster, tamamlanınca completion çağrılır
    func showRewarded(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd else {
            completion(false)
            loadRewarded()
            return
        }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            completion(false)
            return
        }

        ad.present(fromRootViewController: root) {
            // Kullanıcı ödülü kazandı
            completion(true)
        }

        rewardedAd = nil
        rewardedReady = false
        loadRewarded()
    }
}
