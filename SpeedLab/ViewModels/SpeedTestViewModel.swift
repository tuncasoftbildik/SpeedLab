import Foundation
import SwiftUI
import UIKit

@MainActor
class SpeedTestViewModel: ObservableObject {
    @Published var phase: SpeedTestPhase = .idle
    @Published var currentSpeed: Double = 0
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var ping: Double = 0
    @Published var jitter: Double = 0
    @Published var progress: Double = 0
    @Published var gaugeValue: Double = 0
    @Published var networkInfo = NetworkInfo()
    @Published var lastResult: SpeedTestResult?
    @Published var showCompletionEffect = false

    private let speedService = SpeedTestService()
    private let networkService = NetworkService()
    private let historyService = HistoryService()
    private var isRunning = false

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func startTest() async {
        guard !isRunning else { return }
        isRunning = true
        resetValues()
        haptic(.medium)

        // Ağ bilgilerini al
        let _ = await networkService.requestLocationPermission()
        networkInfo = await networkService.getNetworkInfo()

        // 1. Ping testi
        phase = .testingPing
        haptic(.light)
        withAnimation(.easeInOut(duration: 0.3)) { progress = 0.1 }

        let pingResult = await speedService.measurePing()
        withAnimation(.spring(response: 0.5)) {
            ping = pingResult.ping
            jitter = pingResult.jitter
            progress = 0.2
        }

        // 2. Download testi
        phase = .testingDownload
        haptic(.light)
        let dl = await speedService.measureDownload { [weak self] p, speed in
            Task { @MainActor in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.progress = 0.2 + p * 0.4
                    self.currentSpeed = speed
                    self.downloadSpeed = speed
                    self.gaugeValue = min(speed / 200.0, 1.0)
                }
            }
        }
        withAnimation(.spring(response: 0.5)) {
            downloadSpeed = dl
            currentSpeed = dl
            gaugeValue = min(dl / 200.0, 1.0)
            progress = 0.6
        }

        // 3. Upload testi
        phase = .testingUpload
        haptic(.light)
        withAnimation(.easeInOut(duration: 0.2)) {
            gaugeValue = 0
            currentSpeed = 0
        }

        let ul = await speedService.measureUpload { [weak self] p, speed in
            Task { @MainActor in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.progress = 0.6 + p * 0.35
                    self.currentSpeed = speed
                    self.uploadSpeed = speed
                    self.gaugeValue = min(speed / 200.0, 1.0)
                }
            }
        }
        withAnimation(.spring(response: 0.5)) {
            uploadSpeed = ul
            currentSpeed = ul
            gaugeValue = min(ul / 200.0, 1.0)
            progress = 1.0
        }

        // Sonuç
        phase = .completed
        hapticNotification(.success)
        withAnimation(.spring(response: 0.6)) {
            showCompletionEffect = true
        }
        let result = SpeedTestResult(
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            ping: ping,
            jitter: jitter,
            ssid: networkInfo.ssid,
            isp: networkInfo.isp,
            ipAddress: networkInfo.ipAddress
        )
        lastResult = result
        historyService.save(result)

        // Her 3 testte 1 interstitial reklam göster
        AdManager.shared.showInterstitialIfNeeded()

        isRunning = false
    }

    private func resetValues() {
        phase = .idle
        currentSpeed = 0
        downloadSpeed = 0
        uploadSpeed = 0
        ping = 0
        jitter = 0
        progress = 0
        gaugeValue = 0
        lastResult = nil
        showCompletionEffect = false
    }
}
