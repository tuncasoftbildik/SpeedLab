import Foundation
import StoreKit
import WidgetKit

@MainActor
class StoreViewModel: ObservableObject {
    @Published var isPro = false {
        didSet {
            guard oldValue != isPro else { return }
            SharedStore().setPro(isPro)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var products: [Product] = []
    @Published var isLoading = false

    static let productIds = ["com.vialab.speedlab.pro.monthly", "com.vialab.speedlab.pro.yearly"]
    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await checkEntitlements() }
        #if DEBUG
        // Ekran görüntüsü/test için: `defaults write com.vialab.speedlab debug_pro -bool true`
        if UserDefaults.standard.bool(forKey: "debug_pro") { isPro = true }
        #endif
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.productIds)
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
                if Self.productIds.contains(transaction.productID) {
                    isPro = true
                    return
                }
            }
        }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debug_pro") { return }
        #endif
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
