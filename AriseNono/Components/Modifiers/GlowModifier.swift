import SwiftUI

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.80), radius: radius * 0.25)
            .shadow(color: color.opacity(0.40), radius: radius * 0.60)
            .shadow(color: color.opacity(0.15), radius: radius)
    }
}

extension View {
    func neonGlow(color: Color = AppTheme.C.cyan, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}
