import Foundation
import Observation

@MainActor
@Observable
final class DayEditorModel {
    typealias SaveHandler = @MainActor (DayPlanDraft) async throws -> Void
    typealias RemoveHandler = @MainActor (Weekday) async throws -> Void

    var draft: DayPlanDraft
    private(set) var isSaving = false
    private(set) var isRemoving = false
    var errorMessage: String?
    var showsDiscardConfirmation = false
    var showsRemoveConfirmation = false

    let wasConfigured: Bool

    private let originalDraft: DayPlanDraft
    private let saveHandler: SaveHandler
    private let removeHandler: RemoveHandler?

    init(
        draft: DayPlanDraft,
        onSave: @escaping SaveHandler,
        onRemove: RemoveHandler? = nil
    ) {
        wasConfigured = draft.isConfigured
        saveHandler = onSave
        removeHandler = onRemove

        var workingDraft = draft
        workingDraft.isConfigured = true
        if workingDraft.activities.isEmpty {
            workingDraft.addActivity()
        }
        originalDraft = workingDraft
        self.draft = workingDraft
    }

    var hasUnsavedChanges: Bool {
        draft != originalDraft
    }

    var canSave: Bool {
        guard !isSaving, !isRemoving else { return false }
        return (try? DayPlanValidator.normalized(draft)) != nil
    }

    var canAddActivity: Bool {
        draft.activities.count < DayPlanValidator.maximumActivities
    }

    var canRemovePlan: Bool {
        wasConfigured && removeHandler != nil
    }

    var durationText: String {
        let duration = draft.durationMinutes
        guard duration > 0, duration < DayPlanDraft.minutesPerDay else {
            return "Velg et intervall mellom 1 time og 23 timer 59 minutter."
        }

        let hours = duration / 60
        let minutes = duration % 60

        if hours == 0 {
            return "\(minutes) min"
        }
        if minutes == 0 {
            return hours == 1 ? "1 time" : "\(hours) timer"
        }
        return "\(hours) t \(minutes) min"
    }

    var validationMessage: String? {
        do {
            _ = try DayPlanValidator.normalized(draft)
            return nil
        } catch {
            return localizedMessage(for: error)
        }
    }

    func addActivity() {
        guard canAddActivity else { return }
        draft.addActivity()
    }

    func removeActivities(at offsets: IndexSet) {
        draft.removeActivities(at: offsets)
    }

    func moveActivities(from offsets: IndexSet, to destination: Int) {
        draft.moveActivities(fromOffsets: offsets, toOffset: destination)
    }

    func setStartMinute(_ minute: Int) {
        draft.setStartMinuteOfDay(minute, preservingDuration: true)
    }

    func setEndMinute(_ minute: Int) {
        draft.setEndMinuteOfDay(minute)
    }

    func save() async -> Bool {
        guard !isSaving else { return false }

        do {
            let normalized = try DayPlanValidator.normalized(draft)
            isSaving = true
            defer { isSaving = false }
            try await saveHandler(normalized)
            draft = normalized
            return true
        } catch {
            errorMessage = localizedMessage(for: error)
            return false
        }
    }

    func removePlan() async -> Bool {
        guard let removeHandler, !isRemoving else { return false }

        do {
            isRemoving = true
            defer { isRemoving = false }
            try await removeHandler(draft.weekday)
            return true
        } catch {
            errorMessage = localizedMessage(for: error)
            return false
        }
    }

    private func localizedMessage(for error: Error) -> String {
        switch error {
        case DayPlanValidationError.invalidStartMinute,
             DayPlanValidationError.invalidEndMinute:
            "Velg et gyldig klokkeslett."
        case DayPlanValidationError.invalidDuration:
            "Happy Hour må vare mellom 1 time og 23 timer 59 minutter."
        case DayPlanValidationError.invalidActivityCount:
            "Legg til mellom én og ti aktiviteter."
        case DayPlanValidationError.duplicateActivityIdentifier:
            "En aktivitet forekommer mer enn én gang."
        case let DayPlanValidationError.emptyActivityName(index):
            "Aktivitet \(index + 1) trenger et navn."
        case let DayPlanValidationError.activityNameTooLong(index, limit):
            "Navnet på aktivitet \(index + 1) kan ha maksimalt \(limit) tegn."
        case let DayPlanValidationError.activityDetailsTooLong(index, limit):
            "Notatene til aktivitet \(index + 1) kan ha maksimalt \(limit) tegn."
        default:
            error.localizedDescription
        }
    }
}
