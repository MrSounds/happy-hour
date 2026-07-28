import Foundation

struct ActivityDraft: Identifiable, Equatable, Hashable, Sendable {
    var id: UUID
    var name: String
    var details: String
    var colorToken: ActivityColorToken

    init(
        id: UUID = UUID(),
        name: String = "",
        details: String = "",
        colorToken: ActivityColorToken = .dustySage
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.colorToken = colorToken
    }

    init(activity: ActivityModel) {
        self.init(
            id: activity.id,
            name: activity.name,
            details: activity.details ?? "",
            colorToken: activity.colorToken
        )
    }
}

struct DayPlanDraft: Equatable, Sendable {
    static let minutesPerDay = 24 * 60
    static let defaultStartMinuteOfDay = 18 * 60
    static let defaultEndMinuteOfDay = 19 * 60

    var weekday: Weekday
    var isConfigured: Bool
    var startMinuteOfDay: Int
    var endMinuteOfDay: Int
    var endDayOffset: Int
    var activities: [ActivityDraft]

    init(
        weekday: Weekday,
        isConfigured: Bool = false,
        startMinuteOfDay: Int = defaultStartMinuteOfDay,
        endMinuteOfDay: Int = defaultEndMinuteOfDay,
        endDayOffset: Int = 0,
        activities: [ActivityDraft] = []
    ) {
        self.weekday = weekday
        self.isConfigured = isConfigured
        self.startMinuteOfDay = startMinuteOfDay
        self.endMinuteOfDay = endMinuteOfDay
        self.endDayOffset = endDayOffset
        self.activities = activities
    }

    init(plan: DayPlanModel) {
        self.init(
            weekday: plan.weekday,
            isConfigured: plan.isConfigured,
            startMinuteOfDay: plan.startMinuteOfDay,
            endMinuteOfDay: plan.endMinuteOfDay,
            endDayOffset: plan.endDayOffset,
            activities: plan.sortedActivities.map(ActivityDraft.init(activity:))
        )
    }

    var durationMinutes: Int {
        endDayOffset * Self.minutesPerDay
            + endMinuteOfDay
            - startMinuteOfDay
    }

    var endsNextDay: Bool {
        endDayOffset == 1
    }

    func hasChanges(from plan: DayPlanModel) -> Bool {
        self != DayPlanDraft(plan: plan)
    }

    mutating func setStartMinuteOfDay(
        _ minute: Int,
        preservingDuration: Bool = true
    ) {
        if preservingDuration, (1..<Self.minutesPerDay).contains(durationMinutes) {
            let totalEnd = minute + durationMinutes
            startMinuteOfDay = minute
            endMinuteOfDay = totalEnd % Self.minutesPerDay
            endDayOffset = totalEnd >= Self.minutesPerDay ? 1 : 0
        } else {
            startMinuteOfDay = minute
            endDayOffset = Self.derivedEndDayOffset(
                startMinuteOfDay: minute,
                endMinuteOfDay: endMinuteOfDay
            )
        }
    }

    mutating func setEndMinuteOfDay(_ minute: Int) {
        endMinuteOfDay = minute
        endDayOffset = Self.derivedEndDayOffset(
            startMinuteOfDay: startMinuteOfDay,
            endMinuteOfDay: minute
        )
    }

    @discardableResult
    mutating func addActivity(
        name: String = "",
        details: String = ""
    ) -> ActivityDraft? {
        guard activities.count < DayPlanValidator.maximumActivities else {
            return nil
        }

        let activity = ActivityDraft(
            name: name,
            details: details,
            colorToken: .forPosition(activities.count)
        )
        activities.append(activity)
        return activity
    }

    mutating func removeActivities(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) where activities.indices.contains(offset) {
            activities.remove(at: offset)
        }
    }

    mutating func moveActivities(
        fromOffsets offsets: IndexSet,
        toOffset destination: Int
    ) {
        let validOffsets = offsets.filter(activities.indices.contains).sorted()
        guard !validOffsets.isEmpty else {
            return
        }

        let moving = validOffsets.map { activities[$0] }
        for offset in validOffsets.reversed() {
            activities.remove(at: offset)
        }

        let removedBeforeDestination = validOffsets.count { $0 < destination }
        let adjustedDestination = max(
            0,
            min(activities.count, destination - removedBeforeDestination)
        )
        activities.insert(contentsOf: moving, at: adjustedDestination)
    }

    static func derivedEndDayOffset(
        startMinuteOfDay: Int,
        endMinuteOfDay: Int
    ) -> Int {
        endMinuteOfDay > startMinuteOfDay ? 0 : 1
    }
}
