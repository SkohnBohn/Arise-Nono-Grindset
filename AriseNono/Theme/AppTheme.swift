import SwiftUI

enum AppTheme {

    // MARK: - Colors
    enum C {
        static let void    = Color(hex: "07070F")
        static let ink     = Color(hex: "0D0D1E")
        static let steel   = Color(hex: "171729")
        static let rim     = Color(hex: "1E1E38")
        static let cyan    = Color(hex: "00CFEE")
        static let cyanDim = Color(hex: "00677A")
        static let mag     = Color(hex: "B82CF5")
        static let magDim  = Color(hex: "5A1680")
        static let smoke   = Color(hex: "7B7BA0")
        static let ash     = Color(hex: "B8BAD8")
        static let snow    = Color(hex: "E2E4F2")
        static let gold    = Color(hex: "F5B800")
        static let danger  = Color(hex: "FF4060")

        // Rank tier colours
        static func rank(_ tier: RankTier) -> Color {
            switch tier {
            case .unranked:  return smoke
            case .iron:      return Color(hex: "8888AA")
            case .bronze:    return Color(hex: "C4824A")
            case .silver:    return Color(hex: "A8AEC8")
            case .gold:      return gold
            case .platinum:  return Color(hex: "70C8E8")
            case .diamond:   return Color(hex: "A0D8FF")
            case .awakened:  return mag
            }
        }

        // Quest category accent
        static func questCategory(_ cat: QuestCategory) -> Color {
            switch cat {
            case .strength:    return cyan
            case .cardio:      return mag
            case .consistency: return Color(hex: "00FF88")
            }
        }
    }

    // MARK: - Typography
    enum T {
        // Display — moment cards and large headers
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .black, design: .default)
        }
        // HUD heading — all-caps section labels
        static func heading(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }
        // Terminal mono — stats, numbers, labels
        static func mono(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
        // Body
        static func body(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular)
        }
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
