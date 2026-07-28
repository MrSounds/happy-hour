import Foundation

/// Supplies a calendar whose time zone follows the user's current local settings.
protocol CalendarProvider: Sendable {
    var calendar: Calendar { get }
}

struct SystemCalendarProvider: CalendarProvider {
    var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }
}

struct FixedCalendarProvider: CalendarProvider {
    let calendar: Calendar
}
