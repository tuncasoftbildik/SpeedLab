import SwiftUI

/// Canlı akış grafiği: indirme (cyan dolgu + çizgi), yükleme (mor kesik çizgi), son nokta beyaz.
/// Boş dizide düz çizgi; Y ekseni dizilerin maksimumuna göre.
struct LiveFlowGraph: View {
    let download: [Double]
    let upload: [Double]
    var height: CGFloat = 110

    var body: some View {
        Canvas { ctx, size in
            let inset: CGFloat = 8
            let w = size.width - inset * 2
            let h = size.height - inset * 2
            let maxV = max((download + upload).max() ?? 1, 1)

            // Yatay kılavuz
            for i in 1...3 {
                let y = inset + h * CGFloat(i) / 4
                var g = Path(); g.move(to: CGPoint(x: inset, y: y)); g.addLine(to: CGPoint(x: inset + w, y: y))
                ctx.stroke(g, with: .color(Color.npTextSecondary.opacity(0.12)), lineWidth: 0.5)
            }

            func points(_ xs: [Double]) -> [CGPoint] {
                guard xs.count > 1 else {
                    let y = inset + h - h * CGFloat((xs.first ?? 0) / maxV)
                    return [CGPoint(x: inset, y: y), CGPoint(x: inset + w, y: y)]
                }
                return xs.enumerated().map { i, v in
                    CGPoint(x: inset + w * CGFloat(i) / CGFloat(xs.count - 1),
                            y: inset + h - h * CGFloat(min(max(v, 0), maxV) / maxV))
                }
            }

            func line(_ pts: [CGPoint]) -> Path {
                var p = Path(); guard let f = pts.first else { return p }
                p.move(to: f)
                for i in 1..<pts.count {
                    let prev = pts[i - 1], cur = pts[i]
                    let mid = CGPoint(x: (prev.x + cur.x) / 2, y: (prev.y + cur.y) / 2)
                    p.addQuadCurve(to: mid, control: prev)
                }
                if let l = pts.last { p.addLine(to: l) }
                return p
            }

            // İndirme
            let dl = points(download)
            var area = line(dl)
            area.addLine(to: CGPoint(x: dl.last!.x, y: inset + h))
            area.addLine(to: CGPoint(x: dl.first!.x, y: inset + h))
            area.closeSubpath()
            ctx.fill(area, with: .linearGradient(
                Gradient(colors: [Color.npCyan.opacity(0.35), Color.npCyan.opacity(0)]),
                startPoint: CGPoint(x: 0, y: inset), endPoint: CGPoint(x: 0, y: inset + h)))
            ctx.stroke(line(dl), with: .color(download.isEmpty ? Color.npTextSecondary.opacity(0.4) : .npCyan),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // Yükleme
            if !upload.isEmpty {
                ctx.stroke(line(points(upload)), with: .color(.npPurple),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))
            }

            // Son nokta
            if !download.isEmpty, let last = dl.last {
                ctx.fill(Path(ellipseIn: CGRect(x: last.x - 7, y: last.y - 7, width: 14, height: 14)), with: .color(.white.opacity(0.18)))
                ctx.fill(Path(ellipseIn: CGRect(x: last.x - 3.5, y: last.y - 3.5, width: 7, height: 7)), with: .color(.white))
            }
        }
        .frame(height: height)
    }
}
