import UIKit

/// UIActivityViewController'ı kök görünümden sunar (SpeedTestView ve HistoryView ortak).
enum ShareSheet {
    @MainActor
    static func present(items: [Any]) {
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        av.popoverPresentationController?.sourceView = top.view
        av.popoverPresentationController?.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
        av.popoverPresentationController?.permittedArrowDirections = []
        top.present(av, animated: true)
    }

    /// Veriyi geçici dosyaya yazıp paylaşır (dosya adı paylaşım sayfasında görünür).
    @MainActor
    static func presentFile(data: Data, name: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? data.write(to: url, options: .atomic)
        present(items: [url])
    }
}
