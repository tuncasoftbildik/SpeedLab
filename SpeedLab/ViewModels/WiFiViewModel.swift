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
        let strength: Int
    }

    func refresh() async {
        let _ = await networkService.requestLocationPermission()
        networkInfo = await networkService.getNetworkInfo()
        connectionType = networkService.getConnectionType()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        signalHistory = []

        monitorTask = Task {
            while !Task.isCancelled && isMonitoring {
                await refresh()
                let point = SignalPoint(timestamp: Date(), strength: networkInfo.signalStrength)
                signalHistory.append(point)
                if signalHistory.count > 60 { signalHistory.removeFirst() }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 saniye
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
    }
}
