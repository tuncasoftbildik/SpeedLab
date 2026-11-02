import Foundation

class SpeedTestService {
    private let pingURL = "https://speed.cloudflare.com/__down?bytes=0"

    private let downloadTests: [(url: String, expectedBytes: Int)] = [
        ("https://speed.cloudflare.com/__down?bytes=1000000", 1_000_000),
        ("https://speed.cloudflare.com/__down?bytes=5000000", 5_000_000),
        ("https://speed.cloudflare.com/__down?bytes=10000000", 10_000_000),
    ]

    private let uploadURL = "https://speed.cloudflare.com/__up"

    // MARK: - Ping Test
    func measurePing(count: Int = 10) async -> (ping: Double, jitter: Double, loss: Double) {
        var pings: [Double] = []

        for _ in 0..<count {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                var request = URLRequest(url: URL(string: pingURL)!)
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                request.timeoutInterval = 10
                let _ = try await URLSession.shared.data(for: request)
                let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                pings.append(elapsed)
            } catch {
                continue
            }
        }

        let loss = count > 0 ? Double(count - pings.count) / Double(count) : 0
        guard pings.count >= 2 else { return (0, 0, loss) }

        let sorted = pings.sorted()
        let trimmed = Array(sorted.dropFirst().dropLast())
        let avgPing = trimmed.isEmpty ? sorted.reduce(0, +) / Double(sorted.count) : trimmed.reduce(0, +) / Double(trimmed.count)

        var jitterSum = 0.0
        for i in 1..<pings.count {
            jitterSum += abs(pings[i] - pings[i - 1])
        }
        let jitter = jitterSum / Double(pings.count - 1)

        return (avgPing, jitter, loss)
    }

    // MARK: - Download Test
    // progressHandler: (ilerleme 0-1, anlık hız Mbps)
    func measureDownload(progressHandler: @escaping (Double, Double) -> Void) async -> Double {
        var speeds: [Double] = []

        for (index, test) in downloadTests.enumerated() {
            guard let url = URL(string: test.url) else { continue }

            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 30

            let start = CFAbsoluteTimeGetCurrent()
            do {
                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForResource = 30
                let session = URLSession(configuration: config)
                let (bytes, _) = try await session.bytes(for: request)

                var totalBytes = 0
                var windowStart = start
                var windowBytes = 0
                for try await _ in bytes {
                    totalBytes += 1
                    if totalBytes % 50_000 == 0 {
                        // Anlık hız: son pencere (≥ 0.2 sn) içindeki bayt/süre; grafik dalgalanmayı görsün.
                        let now = CFAbsoluteTimeGetCurrent()
                        let windowElapsed = now - windowStart
                        guard windowElapsed >= 0.2 else { continue }
                        let currentSpeed = Double(totalBytes - windowBytes) * 8.0 / 1_000_000.0 / windowElapsed
                        windowStart = now
                        windowBytes = totalBytes

                        let baseProgress = Double(index) / Double(downloadTests.count)
                        let subProgress = min(Double(totalBytes) / Double(test.expectedBytes), 1.0)
                        let totalProgress = baseProgress + subProgress / Double(downloadTests.count)

                        progressHandler(min(totalProgress, 1.0), currentSpeed)
                    }
                }

                let elapsed = CFAbsoluteTimeGetCurrent() - start
                guard elapsed > 0 else { continue }
                let megabits = Double(totalBytes) * 8.0 / 1_000_000.0
                let speed = megabits / elapsed
                speeds.append(speed)

                session.invalidateAndCancel()
            } catch {
                continue
            }
        }

        guard !speeds.isEmpty else { return 0 }
        let meaningful = speeds.count > 1 ? Array(speeds.dropFirst()) : speeds
        return meaningful.max() ?? 0
    }

    // MARK: - Upload Test
    // progressHandler: (ilerleme 0-1, anlık hız Mbps)
    func measureUpload(progressHandler: @escaping (Double, Double) -> Void) async -> Double {
        let sizes = [500_000, 1_000_000, 2_000_000]
        var speeds: [Double] = []

        for (index, size) in sizes.enumerated() {
            guard let url = URL(string: uploadURL) else { continue }

            let payload = Data(count: size)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 30

            let start = CFAbsoluteTimeGetCurrent()
            do {
                let config = URLSessionConfiguration.ephemeral
                let session = URLSession(configuration: config)
                let (_, _) = try await session.upload(for: request, from: payload)
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                guard elapsed > 0 else { continue }
                let megabits = Double(size) * 8.0 / 1_000_000.0
                let speed = megabits / elapsed
                speeds.append(speed)

                let progress = Double(index + 1) / Double(sizes.count)
                progressHandler(progress, speed)

                session.invalidateAndCancel()
            } catch {
                continue
            }
        }

        guard !speeds.isEmpty else { return 0 }
        return speeds.max() ?? 0
    }
}
