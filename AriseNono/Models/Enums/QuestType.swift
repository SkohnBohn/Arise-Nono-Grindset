import Foundation

enum QuestType: String, Codable, CaseIterable, Identifiable {
    case daily, weekly

    var id: String { rawValue }
}
