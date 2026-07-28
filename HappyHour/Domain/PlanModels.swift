import Foundation
import SwiftData

@Model
final class DayPlanModel {
    @Attribute(.unique) var weekdayISO: Int
    var id: UUID
    var isConfigured: Bool
    var startMinuteOfDay: Int
    var endMinuteOfDay: Int
    var endDayOffset: Int

    @Relationship(deleteRule: .cascade, inverse: \ActivityModel.dayPlan)
    var activities: [ActivityModel]

    init(
        id: UUID = UUID(),
        weekday: Weekday,
        isConfigured: Bool = false,
        startMinuteOfDay: Int = DayPlanDraft.defaultStartMinuteOfDay,
        endMinuteOfDay: Int = DayPlanDraft.defaultEndMinuteOfDay,
        endDayOffset: Int = 0,
        activities: [ActivityModel] = []
    ) {
        self.id = id
        self.weekdayISO = weekday.rawValue
        self.isConfigured = isConfigured
        self.startMinuteOfDay = startMinuteOfDay
        self.endMinuteOfDay = endMinuteOfDay
        self.endDayOffset = endDayOffset
        self.activities = activities
    }

    var weekday: Weekday {
        get { Weekday(rawValue: weekdayISO) ?? .monday }
        set { weekdayISO = newValue.rawValue }
    }

    var sortedActivities: [ActivityModel] {
        activities.sorted {
            if $0.sortIndex == $1.sortIndex {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.sortIndex < $1.sortIndex
        }
    }

    var durationMinutes: Int {
        endDayOffset * DayPlanDraft.minutesPerDay
            + endMinuteOfDay
            - startMinuteOfDay
    }

    var snapshot: DayPlanSnapshot {
        DayPlanSnapshot(
            id: id,
            weekday: weekday,
            isConfigured: isConfigured,
            startMinuteOfDay: startMinuteOfDay,
            endMinuteOfDay: endMinuteOfDay,
            endDayOffset: endDayOffset,
            activities: sortedActivities.map(\.snapshot)
        )
    }
}

@Model
final class ActivityModel {
    var id: UUID
    var name: String
    var details: String?
    var sortIndex: Int
    var colorTokenRawValue: String
    var dayPlan: DayPlanModel?

    init(
        id: UUID = UUID(),
        name: String,
        details: String? = nil,
        sortIndex: Int,
        colorToken: ActivityColorToken,
        dayPlan: DayPlanModel? = nil
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.sortIndex = sortIndex
        self.colorTokenRawValue = colorToken.rawValue
        self.dayPlan = dayPlan
    }

    var colorToken: ActivityColorToken {
        get { ActivityColorToken(rawValue: colorTokenRawValue) ?? .dustySage }
        set { colorTokenRawValue = newValue.rawValue }
    }

    var snapshot: ActivitySnapshot {
        ActivitySnapshot(
            id: id,
            name: name,
            details: details,
            sortIndex: sortIndex,
            colorToken: colorToken
        )
    }
}
