import Foundation
import SwiftUI

@MainActor
class WiFiViewModel: ObservableObject {
    @Published var networkInfo = NetworkInfo()
    @Published var signalHistory: [SignalPoint] = []
    @Published var isMonitoring = false
    @Published var connectionType = "WiFi"

    private let networkService = NetworkService()
    private var monitorTask: Task<Void, Never>?

    struct SignalPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let quality: Double
    }

    /// Sinyal değeri hiç gelmiyorsa (simülatör, kısıtlı cihaz) grafik gizlenir.
    var hasSignalData: Bool { signalHistory.contains { $0.quality > 0 } }

    func refresh() async {
        let _ = await networkService.requestLocationPermission()
        networkInfo = await networkService.getNetworkInfo()
        connectionType = networkService.getConnectionType()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        signalHistory = []

        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isMonitoring else { break }
                let hotspot = await self.networkService.fetchHotspot()
                if let q = hotspot.quality { self.networkInfo.signalQuality = q }
                self.signalHistory.append(SignalPoint(timestamp: Date(), quality: hotspot.quality ?? 0))
                if self.signalHistory.count > 30 { self.signalHistory.removeFirst() }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sn × 30 = 60 sn
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
    }
}
