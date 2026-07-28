import Foundation

/// ISO-8601 weekday values. The persisted value is intentionally independent
/// of the user's locale and Foundation's Sunday-first weekday numbering.
enum Weekday: Int, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Int { rawValue }

    var isoWeekday: Int { rawValue }

    /// Foundation calendar components use Sunday = 1 ... Saturday = 7.
    var foundationWeekday: Int {
        rawValue == 7 ? 1 : rawValue + 1
    }

    init?(isoWeekday: Int) {
        self.init(rawValue: isoWeekday)
    }

    init?(foundationWeekday: Int) {
        guard (1...7).contains(foundationWeekday) else {
            return nil
        }

        self.init(rawValue: foundationWeekday == 1 ? 7 : foundationWeekday - 1)
    }

    static func current(
        in calendar: Calendar = .autoupdatingCurrent,
        at date: Date = .now
    ) -> Weekday {
        let value = calendar.component(.weekday, from: date)
        return Weekday(foundationWeekday: value) ?? .monday
    }

    var displayName: String {
        localizedName(width: .wide)
    }

    var shortDisplayName: String {
        localizedName(width: .abbreviated)
    }

    func localizedName(
        locale: Locale = .autoupdatingCurrent,
        width: NameWidth = .wide
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale

        let symbols: [String]
        switch width {
        case .wide:
            symbols = formatter.weekdaySymbols
        case .abbreviated:
            symbols = formatter.shortWeekdaySymbols
        case .veryShort:
            symbols = formatter.veryShortWeekdaySymbols
        }

        return symbols[foundationWeekday - 1]
    }
}

extension Weekday {
    enum NameWidth: Sendable {
        case wide
        case abbreviated
        case veryShort
    }
}
