import Foundation

enum LevelCurve {
    static let base: Double = 80
    static let exponent: Double = 1.5

    // Index = level, value = XP required to reach that level from the previous one.
    // Precomputed once to avoid repeated pow() calls at runtime.
    private static let table: [Int] = {
        var t = [0] // level 0 costs nothing
        for lvl in 1...200 {
            t.append(Int(base * pow(Double(lvl), exponent)))
        }
        return t
    }()

    static func xpRequired(toReach level: Int) -> Int {
        guard level > 0, level < table.count else { return 0 }
        return table[level]
    }

    // Total XP needed to reach `level` from scratch.
    static func cumulativeXP(forLevel level: Int) -> Int {
        guard level > 0 else { return 0 }
        return (1...level).reduce(0) { $0 + xpRequired(toReach: $1) }
    }

    // Derive level from a total XP value.
    static func level(forTotalXP xp: Int) -> Int {
        var lvl = 0
        var cumulative = 0
        while lvl < 200 {
            let needed = xpRequired(toReach: lvl + 1)
            guard cumulative + needed <= xp else { break }
            cumulative += needed
            lvl += 1
        }
        return lvl
    }

    // Progress within the current level: (pointsEarned, pointsNeeded, fraction 0–1).
    static func progress(totalXP: Int) -> (earned: Int, needed: Int, fraction: Double) {
        let lvl = level(forTotalXP: totalXP)
        let base = cumulativeXP(forLevel: lvl)
        let needed = xpRequired(toReach: lvl + 1)
        let earned = totalXP - base
        return (earned, needed, Double(earned) / Double(max(needed, 1)))
    }
}
