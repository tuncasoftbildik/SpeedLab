import Foundation
import NetworkExtension
import CoreLocation
import Network

class NetworkService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // WiFi bilgileri için konum izni gerekli (iOS 13+)
    func requestLocationPermission() async -> Bool {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            return true
        }
        if status == .denied || status == .restricted {
            return false
        }

        return await withCheckedContinuation { continuation in
            self.authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation = authorizationContinuation else { return }
        authorizationContinuation = nil
        let granted = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        continuation.resume(returning: granted)
    }

    // MARK: - WiFi SSID (NEHotspotNetwork — iOS 14+)
    func getCurrentSSID() async -> String {
        #if targetEnvironment(simulator)
        return "Simulator WiFi"
        #else
        if let network = await NEHotspotNetwork.fetchCurrent() {
            return network.ssid
        }
        return "-"
        #endif
    }

    // MARK: - IP Address
    func getLocalIPAddress() -> String {
        var address = "-"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return address }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }

    // MARK: - Public IP & ISP
    func getPublicIPInfo() async -> (ip: String, isp: String) {
        do {
            let url = URL(string: "https://ipinfo.io/json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let ip = json["ip"] as? String ?? "-"
                let org = json["org"] as? String ?? "-"
                // "AS12345 Turk Telekom" -> "Turk Telekom"
                let isp = org.components(separatedBy: " ").dropFirst().joined(separator: " ")
                return (ip, isp.isEmpty ? org : isp)
            }
        } catch {}
        return ("-", "-")
    }

    // MARK: - Connection Type
    func getConnectionType() -> String {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "network-monitor")
        var result = "Bilinmiyor"

        let semaphore = DispatchSemaphore(value: 0)
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                result = "WiFi"
            } else if path.usesInterfaceType(.cellular) {
                result = "Hücresel"
            } else if path.usesInterfaceType(.wiredEthernet) {
                result = "Ethernet"
            } else {
                result = "Bilinmiyor"
            }
            semaphore.signal()
        }
        monitor.start(queue: queue)
        semaphore.wait()
        monitor.cancel()
        return result
    }

    // MARK: - Full Network Info
    func getNetworkInfo() async -> NetworkInfo {
        var info = NetworkInfo()
        info.ssid = await getCurrentSSID()
        info.ipAddress = getLocalIPAddress()

        let publicInfo = await getPublicIPInfo()
        info.isp = publicInfo.isp

        return info
    }
}
