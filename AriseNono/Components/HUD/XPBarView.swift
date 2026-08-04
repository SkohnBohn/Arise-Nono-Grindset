import SwiftUI

struct XPBarView: View {
    var fraction: Double   // 0–1
    var label: String?

    @State private var animatedFraction: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(AppTheme.T.mono(9))
                    .foregroundStyle(AppTheme.C.smoke)
                    .kerning(2)
                    .textCase(.uppercase)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(AppTheme.C.rim)
                        .frame(height: 6)

                    // Fill
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.C.gold, AppTheme.C.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedFraction, height: 6)
                        .neonGlow(color: AppTheme.C.gold, radius: 6)
                }
                .clipShape(Rectangle())
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animatedFraction = fraction }
        }
        .onChange(of: fraction) { _, new in
            withAnimation(.easeOut(duration: 0.5)) { animatedFraction = new }
        }
    }
}
