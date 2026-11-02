import Foundation

/// Canlı hız örnekleri için sabit kapasiteli tampon; dolunca en eskiyi atar.
struct SampleBuffer {
    let capacity: Int
    private(set) var values: [Double] = []

    init(capacity: Int = 60) {
        self.capacity = max(1, capacity)
    }

    mutating func append(_ value: Double) {
        values.append(value)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
    }

    mutating func reset() { values.removeAll(keepingCapacity: true) }
}
