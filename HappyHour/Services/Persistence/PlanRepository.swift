import Foundation
import SwiftData

@MainActor
final class PlanRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.modelContext.autosaveEnabled = false
    }

    convenience init(modelContainer: ModelContainer) {
        self.init(modelContext: modelContainer.mainContext)
    }

    /// Repairs the fixed weekly skeleton and persists it in one save. Existing
    /// configured rows win over unconfigured duplicates if an older/broken
    /// store somehow contains them.
    @discardableResult
    func seedWeekIfNeeded() throws -> [DayPlanModel] {
        let existing = try modelContext.fetch(FetchDescriptor<DayPlanModel>())
        var changed = false

        for invalid in existing where Weekday(rawValue: invalid.weekdayISO) == nil {
            modelContext.delete(invalid)
            changed = true
        }

        for weekday in Weekday.allCases {
            let matches = existing.filter { $0.weekdayISO == weekday.rawValue }
            if matches.isEmpty {
                modelContext.insert(DayPlanModel(weekday: weekday))
                changed = true
                continue
            }

            let keeper = matches.first(where: \.isConfigured) ?? matches[0]
            for duplicate in matches where duplicate !== keeper {
                modelContext.delete(duplicate)
                changed = true
            }
        }

        if changed {
            try saveOrRollback()
        }

        return try fetchAllPlans()
    }

    func fetchAllPlans() throws -> [DayPlanModel] {
        let descriptor = FetchDescriptor<DayPlanModel>(
            sortBy: [SortDescriptor(\DayPlanModel.weekdayISO)]
        )
        return try modelContext.fetch(descriptor)
    }

    func plan(for weekday: Weekday) throws -> DayPlanModel? {
        let isoWeekday = weekday.rawValue
        var descriptor = FetchDescriptor<DayPlanModel>(
            predicate: #Predicate { $0.weekdayISO == isoWeekday }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Validates the complete value draft before mutating the model context.
    /// A failed context save is rolled back, so no partial edit is retained.
    @discardableResult
    func save(_ draft: DayPlanDraft) throws -> DayPlanModel {
        guard draft.isConfigured else {
            return try removePlan(for: draft.weekday)
        }

        let normalized = try DayPlanValidator.normalized(draft)
        let plan = try existingOrNewPlan(for: normalized.weekday)

        plan.isConfigured = true
        plan.startMinuteOfDay = normalized.startMinuteOfDay
        plan.endMinuteOfDay = normalized.endMinuteOfDay
        plan.endDayOffset = normalized.endDayOffset

        let existingByID = Dictionary(
            plan.activities.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let retainedIDs = Set(normalized.activities.map(\.id))
        var orderedModels: [ActivityModel] = []

        for (sortIndex, activityDraft) in normalized.activities.enumerated() {
            let activity: ActivityModel
            if let existingActivity = existingByID[activityDraft.id] {
                activity = existingActivity
                activity.name = activityDraft.name
                activity.details = activityDraft.details.nilIfEmpty
                activity.sortIndex = sortIndex
                activity.colorToken = activityDraft.colorToken
                activity.dayPlan = plan
            } else {
                activity = ActivityModel(
                    id: activityDraft.id,
                    name: activityDraft.name,
                    details: activityDraft.details.nilIfEmpty,
                    sortIndex: sortIndex,
                    colorToken: activityDraft.colorToken,
                    dayPlan: plan
                )
                modelContext.insert(activity)
            }
            orderedModels.append(activity)
        }

        for removedActivity in plan.activities where !retainedIDs.contains(removedActivity.id) {
            modelContext.delete(removedActivity)
        }

        plan.activities = orderedModels
        try saveOrRollback()
        return plan
    }

    /// Removing a Happy Hour resets its fixed weekday slot instead of deleting
    /// that slot, preserving the invariant that the store always has seven days.
    @discardableResult
    func removePlan(for weekday: Weekday) throws -> DayPlanModel {
        let plan = try existingOrNewPlan(for: weekday)
        let previousActivities = plan.activities

        plan.isConfigured = false
        plan.startMinuteOfDay = DayPlanDraft.defaultStartMinuteOfDay
        plan.endMinuteOfDay = DayPlanDraft.defaultEndMinuteOfDay
        plan.endDayOffset = 0
        plan.activities = []
        previousActivities.forEach(modelContext.delete)

        try saveOrRollback()
        return plan
    }

    private func existingOrNewPlan(for weekday: Weekday) throws -> DayPlanModel {
        if let existing = try plan(for: weekday) {
            return existing
        }

        let plan = DayPlanModel(weekday: weekday)
        modelContext.insert(plan)
        return plan
    }

    private func saveOrRollback() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
