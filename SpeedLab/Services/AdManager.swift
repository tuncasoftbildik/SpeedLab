import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // Ad Unit IDs
    static let bannerAdUnitID = "ca-app-pub-3770969986981001/3125134660"
    static let interstitialAdUnitID = "ca-app-pub-3770969986981001/6092312428"

    @Published var interstitialReady = false
    private var interstitialAd: GADInterstitialAd?

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
}
