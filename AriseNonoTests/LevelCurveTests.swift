import XCTest
@testable import AriseNono

final class LevelCurveTests: XCTestCase {

    func test_xpRequired_level1_is80() {
        XCTAssertEqual(LevelCurve.xpRequired(toReach: 1), 80)
    }

    func test_xpRequired_level0_is0() {
        XCTAssertEqual(LevelCurve.xpRequired(toReach: 0), 0)
    }

    func test_xpRequired_increases_with_level() {
        for lvl in 1..<50 {
            XCTAssertLessThan(LevelCurve.xpRequired(toReach: lvl),
                              LevelCurve.xpRequired(toReach: lvl + 1),
                              "XP to reach level \(lvl+1) should be greater than level \(lvl)")
        }
    }

    func test_cumulativeXP_level0_is0() {
        XCTAssertEqual(LevelCurve.cumulativeXP(forLevel: 0), 0)
    }

    func test_cumulativeXP_level1_equals_xpRequired_1() {
        XCTAssertEqual(LevelCurve.cumulativeXP(forLevel: 1), LevelCurve.xpRequired(toReach: 1))
    }

    func test_level_at_0xp_is_0() {
        XCTAssertEqual(LevelCurve.level(forTotalXP: 0), 0)
    }

    func test_level_roundtrip() {
        // For any level, earning exactly the cumulative XP should land on that level
        for lvl in 1...30 {
            let xp = LevelCurve.cumulativeXP(forLevel: lvl)
            XCTAssertEqual(LevelCurve.level(forTotalXP: xp), lvl,
                           "At cumulative XP for level \(lvl), level should be \(lvl)")
        }
    }

    func test_level_just_below_threshold() {
        let xpForLevel5 = LevelCurve.cumulativeXP(forLevel: 5)
        XCTAssertEqual(LevelCurve.level(forTotalXP: xpForLevel5 - 1), 4)
    }

    func test_progress_fraction_is_0_at_level_boundary() {
        let xp = LevelCurve.cumulativeXP(forLevel: 10)
        let (earned, _, fraction) = LevelCurve.progress(totalXP: xp)
        XCTAssertEqual(earned, 0)
        XCTAssertEqual(fraction, 0, accuracy: 0.001)
    }

    func test_progress_fraction_is_between_0_and_1() {
        let xp = LevelCurve.cumulativeXP(forLevel: 5) + 100
        let (_, _, fraction) = LevelCurve.progress(totalXP: xp)
        XCTAssertGreaterThan(fraction, 0)
        XCTAssertLessThanOrEqual(fraction, 1)
    }
}
