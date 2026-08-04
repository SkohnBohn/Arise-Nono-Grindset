import SwiftUI

// A rectangle with one or more corners clipped at 45° — the app's primary panel shape.
struct AngularPanel: Shape {
    var cut: CGFloat = 12
    var corners: RectCorner = .topRight

    func path(in rect: CGRect) -> Path {
        Path { p in
            let tl = corners.contains(.topLeft)
            let tr = corners.contains(.topRight)
            let br = corners.contains(.bottomRight)
            let bl = corners.contains(.bottomLeft)

            p.move(to: CGPoint(x: rect.minX + (tl ? cut : 0), y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - (tr ? cut : 0), y: rect.minY))
            if tr { p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut)) }
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - (br ? cut : 0)))
            if br { p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY)) }
            p.addLine(to: CGPoint(x: rect.minX + (bl ? cut : 0), y: rect.maxY))
            if bl { p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut)) }
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + (tl ? cut : 0)))
            if tl { p.addLine(to: CGPoint(x: rect.minX + cut, y: rect.minY)) }
            p.closeSubpath()
        }
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft     = RectCorner(rawValue: 1 << 0)
    static let topRight    = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft  = RectCorner(rawValue: 1 << 3)
    static let all: RectCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft]
    static let top: RectCorner = [.topLeft, .topRight]
    static let bottom: RectCorner = [.bottomLeft, .bottomRight]
}

// Convenience view modifier for the standard panel look
struct HUDPanel: ViewModifier {
    var cut: CGFloat = 10
    var corners: RectCorner = .topRight
    var borderColor: Color = AppTheme.C.cyanDim
    var fillColor: Color = AppTheme.C.ink

    func body(content: Content) -> some View {
        content
            .background(
                AngularPanel(cut: cut, corners: corners)
                    .fill(fillColor)
            )
            .overlay(
                AngularPanel(cut: cut, corners: corners)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func hudPanel(cut: CGFloat = 10, corners: RectCorner = .topRight,
                  border: Color = AppTheme.C.cyanDim, fill: Color = AppTheme.C.ink) -> some View {
        modifier(HUDPanel(cut: cut, corners: corners, borderColor: border, fillColor: fill))
    }
}
