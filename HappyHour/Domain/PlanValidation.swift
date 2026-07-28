import Foundation

enum DayPlanValidationError: Error, Equatable, LocalizedError, Sendable {
    case invalidStartMinute(Int)
    case invalidEndMinute(Int)
    case invalidDuration(Int)
    case invalidActivityCount(Int)
    case duplicateActivityIdentifier(UUID)
    case emptyActivityName(index: Int)
    case activityNameTooLong(index: Int, limit: Int)
    case activityDetailsTooLong(index: Int, limit: Int)

    var errorDescription: String? {
        switch self {
        case .invalidStartMinute:
            return "Choose a valid start time."
        case .invalidEndMinute:
            return "Choose a valid end time."
        case .invalidDuration:
            return "Happy Hour must last between 60 minutes and 23 hours 59 minutes."
        case .invalidActivityCount:
            return "Add between one and ten activities."
        case .duplicateActivityIdentifier:
            return "An activity appears more than once."
        case let .emptyActivityName(index):
            return "Activity \(index + 1) needs a name."
        case let .activityNameTooLong(index, limit):
            return "Activity \(index + 1) must be \(limit) characters or fewer."
        case let .activityDetailsTooLong(index, limit):
            return "Notes for activity \(index + 1) must be \(limit) characters or fewer."
        }
    }
}

enum DayPlanValidator {
    static let minimumActivities = 1
    static let maximumActivities = 10
    static let minimumDurationMinutes = 60
    static let maximumDurationMinutes = DayPlanDraft.minutesPerDay - 1
    static let maximumNameLength = 40
    static let maximumDetailsLength = 500

    /// Returns a persistence-ready value. End-day offset and whitespace are
    /// normalized only after every constraint has been checked.
    static func normalized(_ draft: DayPlanDraft) throws -> DayPlanDraft {
        guard (0..<DayPlanDraft.minutesPerDay).contains(draft.startMinuteOfDay) else {
            throw DayPlanValidationError.invalidStartMinute(draft.startMinuteOfDay)
        }
        guard (0..<DayPlanDraft.minutesPerDay).contains(draft.endMinuteOfDay) else {
            throw DayPlanValidationError.invalidEndMinute(draft.endMinuteOfDay)
        }

        var normalized = draft
        normalized.endDayOffset = DayPlanDraft.derivedEndDayOffset(
            startMinuteOfDay: draft.startMinuteOfDay,
            endMinuteOfDay: draft.endMinuteOfDay
        )

        guard (minimumDurationMinutes...maximumDurationMinutes)
            .contains(normalized.durationMinutes)
        else {
            throw DayPlanValidationError.invalidDuration(normalized.durationMinutes)
        }

        guard (minimumActivities...maximumActivities).contains(draft.activities.count) else {
            throw DayPlanValidationError.invalidActivityCount(draft.activities.count)
        }

        var identifiers = Set<UUID>()
        for index in normalized.activities.indices {
            let activity = normalized.activities[index]

            guard identifiers.insert(activity.id).inserted else {
                throw DayPlanValidationError.duplicateActivityIdentifier(activity.id)
            }

            let name = activity.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let details = activity.details.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !name.isEmpty else {
                throw DayPlanValidationError.emptyActivityName(index: index)
            }
            guard name.count <= maximumNameLength else {
                throw DayPlanValidationError.activityNameTooLong(
                    index: index,
                    limit: maximumNameLength
                )
            }
            guard details.count <= maximumDetailsLength else {
                throw DayPlanValidationError.activityDetailsTooLong(
                    index: index,
                    limit: maximumDetailsLength
                )
            }

            normalized.activities[index].name = name
            normalized.activities[index].details = details
        }

        normalized.isConfigured = true
        return normalized
    }
}
