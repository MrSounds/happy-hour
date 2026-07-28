import Foundation

/// A semantic palette key persisted with each activity. Rendering the actual
/// color belongs to the design system so the stored model remains UI-agnostic.
enum ActivityColorToken: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case dustySage
    case blueGrey
    case lavender
    case sand
    case softTerracotta

    var id: String { rawValue }

    static func forPosition(_ position: Int) -> ActivityColorToken {
        let count = allCases.count
        let normalizedIndex = ((position % count) + count) % count
        return allCases[normalizedIndex]
    }
}
