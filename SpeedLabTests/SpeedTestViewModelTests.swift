import XCTest
@testable import SpeedLab

@MainActor
final class SpeedTestViewModelTests: XCTestCase {
    private func makeVM() -> (SpeedTestViewModel, () -> Int) {
        let vm = SpeedTestViewModel()
        vm.cardsDelayNs = 20_000_000
        vm.interstitialDelayNs = 20_000_000
        var count = 0
        vm.presentInterstitial = { count += 1 }
        return (vm, { count })
    }

    /// Bitiş dizisi sırasında yeni test başlarsa (koşu kimliği değişir) eski dizi ne kart açar ne reklam gösterir.
    func test_staleRunShowsNeitherCardsNorAd() async {
        let (vm, ads) = makeVM()
        let id = vm.beginRun()
        vm.phase = .completed
        vm.invalidateRun()
        await vm.finishPresentation(runID: id)
        XCTAssertFalse(vm.showResultCards)
        XCTAssertEqual(ads(), 0)
    }

    func test_currentRunShowsCardsThenAd() async {
        let (vm, ads) = makeVM()
        let id = vm.beginRun()
        vm.phase = .completed
        await vm.finishPresentation(runID: id)
        XCTAssertTrue(vm.showResultCards)
        XCTAssertEqual(ads(), 1)
    }

    /// Kartlar açıldıktan sonra, reklam gecikmesi dolmadan faz değişirse reklam gösterilmez.
    /// Geniş zaman payı: kart 10 ms, faz değişimi 120 ms, reklam 500 ms.
    func test_phaseLeftCompletedCancelsAd() async {
        let (vm, ads) = makeVM()
        vm.cardsDelayNs = 10_000_000
        vm.interstitialDelayNs = 500_000_000
        let id = vm.beginRun()
        vm.phase = .completed
        Task { try? await Task.sleep(nanoseconds: 120_000_000); vm.phase = .testingPing }
        await vm.finishPresentation(runID: id)
        XCTAssertTrue(vm.showResultCards)
        XCTAssertEqual(ads(), 0)
    }
}
