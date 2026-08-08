import Foundation

enum AuraCalculator {
    // consistencyFraction and varietyFraction are both 0.0–1.0
    static func compute(consistencyFraction: Double, varietyFraction: Double) -> Double {
        (consistencyFraction * 500.0 + varietyFraction * 500.0).rounded()
    }
}
