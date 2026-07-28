import Foundation

struct ScheduleOccurrence: Equatable, Sendable {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

enum ScheduleResolutionError: Error, Equatable {
    case dayIsNotConfigured
    case invalidStartMinute
    case invalidEndMinute
    case invalidEndDayOffset
    case invalidDuration
    case unableToResolveStart
    case unableToResolveEnd
}

struct ScheduleResolver: Sendable {
    static let minutesPerDay = 1_440

    func nominalDurationMinutes(for schedule: DayPlanSnapshot) throws -> Int {
        guard (0..<Self.minutesPerDay).contains(schedule.startMinuteOfDay) else {
            throw ScheduleResolutionError.invalidStartMinute
        }
        guard (0..<Self.minutesPerDay).contains(schedule.endMinuteOfDay) else {
            throw ScheduleResolutionError.invalidEndMinute
        }
        guard (0...1).contains(schedule.endDayOffset) else {
            throw ScheduleResolutionError.invalidEndDayOffset
        }

        let duration = schedule.endDayOffset * Self.minutesPerDay
            + schedule.endMinuteOfDay
            - schedule.startMinuteOfDay
        guard (60..<Self.minutesPerDay).contains(duration) else {
            throw ScheduleResolutionError.invalidDuration
        }
        return duration
    }

    /// Returns the occurrence containing `date`, or the next occurrence when
    /// the selected day's Happy Hour is not currently active.
    func currentOrNextOccurrence(
        for schedule: DayPlanSnapshot,
        relativeTo date: Date,
        calendar: Calendar
    ) throws -> ScheduleOccurrence {
        guard schedule.isConfigured else {
            throw ScheduleResolutionError.dayIsNotConfigured
        }
        _ = try nominalDurationMinutes(for: schedule)

        if let previousStart = matchingStart(
            for: schedule,
            relativeTo: date.addingTimeInterval(1),
            direction: .backward,
            calendar: calendar
        ) {
            let previous = try occurrence(
                for: schedule,
                startingAt: previousStart,
                calendar: calendar
            )
            if previous.contains(date) {
                return previous
            }
        }

        guard let nextStart = matchingStart(
            for: schedule,
            relativeTo: date,
            direction: .forward,
            calendar: calendar
        ) else {
            throw ScheduleResolutionError.unableToResolveStart
        }
        return try occurrence(for: schedule, startingAt: nextStart, calendar: calendar)
    }

    func occurrence(
        for schedule: DayPlanSnapshot,
        startingAt start: Date,
        calendar: Calendar
    ) throws -> ScheduleOccurrence {
        _ = try nominalDurationMinutes(for: schedule)

        guard let targetDay = calendar.date(
            byAdding: .day,
            value: schedule.endDayOffset,
            to: start
        ) else {
            throw ScheduleResolutionError.unableToResolveEnd
        }

        let endHour = schedule.endMinuteOfDay / 60
        let endMinute = schedule.endMinuteOfDay % 60
        let targetDayStart = calendar.startOfDay(for: targetDay)
        guard
            let searchAnchor = calendar.date(byAdding: .second, value: -1, to: targetDayStart),
            let end = calendar.nextDate(
                after: searchAnchor,
                matching: DateComponents(hour: endHour, minute: endMinute, second: 0),
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .first,
                direction: .forward
            ),
            end > start
        else {
            throw ScheduleResolutionError.unableToResolveEnd
        }

        return ScheduleOccurrence(start: start, end: end)
    }

    private func matchingStart(
        for schedule: DayPlanSnapshot,
        relativeTo date: Date,
        direction: Calendar.SearchDirection,
        calendar: Calendar
    ) -> Date? {
        let startHour = schedule.startMinuteOfDay / 60
        let startMinute = schedule.startMinuteOfDay % 60
        let components = DateComponents(
            hour: startHour,
            minute: startMinute,
            second: 0,
            weekday: schedule.weekday.foundationWeekday
        )

        return calendar.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: direction
        )
    }
}
