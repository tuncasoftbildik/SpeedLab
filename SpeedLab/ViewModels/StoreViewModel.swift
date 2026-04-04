import Foundation
import StoreKit

@MainActor
class StoreViewModel: ObservableObject {
    @Published var isPro = false
    @Published var products: [Product] = []
    @Published var isLoading = false

    private let productIds = ["com.vialab.speedlab.pro.monthly", "com.vialab.speedlab.pro.yearly"]
    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await checkEntitlements() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
        } catch {
            print("Ürünler yüklenemedi: \(error)")
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await transaction.finish()
                isPro = true
                return true
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    private func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? Self.checkVerified(result) {
                if productIds.contains(transaction.productID) {
                    isPro = true
                    return
                }
            }
        }
        isPro = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? Self.checkVerified(result) {
                    await MainActor.run { self.isPro = true }
                    await transaction.finish()
                }
            }
        }
    }

    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let item):
            return item
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
