import SwiftUI

struct StatReadoutView: View {
    var label: String
    var value: String
    var accent: Color = AppTheme.C.cyan
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(compact ? 8 : 9))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1.5)

            Text(value)
                .font(AppTheme.T.mono(compact ? 14 : 18))
                .foregroundStyle(accent)
                .fontWeight(.bold)
                .neonGlow(color: accent, radius: 4)
        }
    }
}
