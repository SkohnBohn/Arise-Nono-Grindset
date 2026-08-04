import SwiftUI

// Subtle animated scanline effect using Canvas + TimelineView.
struct ScanlineOverlay: View {
    var opacity: Double = 0.04

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { _ in
            Canvas { ctx, size in
                let lineSpacing: CGFloat = 4
                var y: CGFloat = 0
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 1)
                    y += lineSpacing
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
