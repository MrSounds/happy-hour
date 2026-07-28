import EventKit
import Foundation

struct CalendarEventDescriptor: Equatable, Sendable {
    let title: String
    let startDate: Date
    let endDate: Date
    let notes: String?
    let timeZone: TimeZone
}

struct CalendarEventBuilder: Sendable {
    private let resolver: ScheduleResolver

    init(resolver: ScheduleResolver = ScheduleResolver()) {
        self.resolver = resolver
    }

    func descriptor(
        for schedule: DayPlanSnapshot,
        relativeTo date: Date,
        calendar: Calendar
    ) throws -> CalendarEventDescriptor {
        let occurrence = try resolver.currentOrNextOccurrence(
            for: schedule,
            relativeTo: date,
            calendar: calendar
        )
        let activityNames = schedule.activities
            .map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let notes = activityNames.isEmpty
            ? nil
            : activityNames.map { "• \($0)" }.joined(separator: "\n")

        return CalendarEventDescriptor(
            title: "Happy Hour",
            startDate: occurrence.start,
            endDate: occurrence.end,
            notes: notes,
            timeZone: calendar.timeZone
        )
    }

    @MainActor
    func makeEvent(
        for schedule: DayPlanSnapshot,
        in eventStore: EKEventStore,
        relativeTo date: Date,
        calendar: Calendar
    ) throws -> EKEvent {
        let descriptor = try descriptor(
            for: schedule,
            relativeTo: date,
            calendar: calendar
        )
        let event = EKEvent(eventStore: eventStore)
        event.title = descriptor.title
        event.startDate = descriptor.startDate
        event.endDate = descriptor.endDate
        event.notes = descriptor.notes
        event.timeZone = descriptor.timeZone
        event.alarms = nil
        event.recurrenceRules = nil
        return event
    }
}
