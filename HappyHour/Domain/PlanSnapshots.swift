import Foundation

/// Immutable values for crossing actor and system-service boundaries without
/// sending SwiftData models outside their model context.
struct ActivitySnapshot: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let details: String?
    let sortIndex: Int
    let colorToken: ActivityColorToken
}

struct DayPlanSnapshot: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let weekday: Weekday
    let isConfigured: Bool
    let startMinuteOfDay: Int
    let endMinuteOfDay: Int
    let endDayOffset: Int
    let activities: [ActivitySnapshot]

    var durationMinutes: Int {
        endDayOffset * DayPlanDraft.minutesPerDay
            + endMinuteOfDay
            - startMinuteOfDay
    }

    var endsNextDay: Bool {
        endDayOffset == 1
    }
}
