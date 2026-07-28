import EventKit
import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class AppModel {
    private enum PreferenceKey {
        static let completedOnboarding = "completedOnboarding"
        static let notificationPrimerSeen = "notificationPrimerSeen"
    }

    private let modelContainer: ModelContainer
    private let repository: PlanRepository
    private let notificationScheduler: NotificationScheduler
    private let notificationDelegate: AppNotificationDelegate
    private let scheduleResolver: ScheduleResolver
    private let calendarEventBuilder: CalendarEventBuilder
    private let clock: any Clock
    private let calendarProvider: any CalendarProvider
    private let preferences: UserDefaults
    private let configuredFixture: Bool
    private let beerMugFixture: Bool
    private var pendingCalendarWeekday: Weekday?
    private var shouldPresentNotificationPrimerAfterEditor = false

    private(set) var plans: [DayPlanModel] = []
    private(set) var isReady = false
    private(set) var activeWeekdays: Set<Weekday> = []
    private(set) var notificationStatus: AppNotificationAuthorizationStatus = .notDetermined

    var selectedWeekday: Weekday
    var editingWeekday: Weekday?
    var isShowingSettings = false
    var isShowingNotificationPrimer = false
    var calendarPresentation: CalendarPresentation?
    var alertMessage: String?
    var transientMessage: String?

    var hasCompletedOnboarding: Bool {
        didSet {
            preferences.set(
                hasCompletedOnboarding,
                forKey: PreferenceKey.completedOnboarding
            )
        }
    }

    var hasConfiguredPlan: Bool {
        plans.contains(where: \.isConfigured)
    }

    init(
        modelContainer: ModelContainer,
        preferences: UserDefaults,
        configuredFixture: Bool = false,
        beerMugFixture: Bool = false,
        notificationScheduler: NotificationScheduler = NotificationScheduler(),
        notificationDelegate: AppNotificationDelegate = AppNotificationDelegate(),
        scheduleResolver: ScheduleResolver = ScheduleResolver(),
        calendarEventBuilder: CalendarEventBuilder = CalendarEventBuilder(),
        clock: any Clock = SystemClock(),
        calendarProvider: any CalendarProvider = SystemCalendarProvider()
    ) {
        self.modelContainer = modelContainer
        self.repository = PlanRepository(modelContainer: modelContainer)
        self.preferences = preferences
        self.configuredFixture = configuredFixture
        self.beerMugFixture = beerMugFixture
        self.notificationScheduler = notificationScheduler
        self.notificationDelegate = notificationDelegate
        self.scheduleResolver = scheduleResolver
        self.calendarEventBuilder = calendarEventBuilder
        self.clock = clock
        self.calendarProvider = calendarProvider

        let today = Weekday.current(
            in: calendarProvider.calendar,
            at: clock.now
        )
        selectedWeekday = today
        hasCompletedOnboarding = preferences.bool(
            forKey: PreferenceKey.completedOnboarding
        )

        notificationDelegate.install { [weak self] weekday in
            self?.selectedWeekday = weekday
        }
    }

    var notificationPresentationState: NotificationSettingsPresentationState {
        switch notificationStatus {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized, .ephemeral:
            .enabled
        case .provisional:
            .provisional
        }
    }

    func bootstrap() async {
        guard !isReady else { return }

        do {
            plans = try repository.seedWeekIfNeeded()
            if beerMugFixture {
                try installBeerMugFixture()
                selectedWeekday = .thursday
                hasCompletedOnboarding = true
                preferences.set(true, forKey: PreferenceKey.notificationPrimerSeen)
            } else if configuredFixture {
                try installConfiguredFixture()
                hasCompletedOnboarding = true
                preferences.set(true, forKey: PreferenceKey.notificationPrimerSeen)
            }
            try refreshPlans()
            refreshActiveState()
            await refreshNotificationStateAndReconcile()
            isReady = true
        } catch {
            alertMessage = friendlyMessage(for: error)
            isReady = true
        }
    }

    func startFirstPlan() {
        editingWeekday = selectedWeekday
    }

    func skipOnboarding() {
        hasCompletedOnboarding = true
    }

    func edit(_ weekday: Weekday) {
        editingWeekday = weekday
    }

    func draft(for weekday: Weekday) -> DayPlanDraft {
        guard let plan = plans.first(where: { $0.weekday == weekday }) else {
            return DayPlanDraft(weekday: weekday)
        }
        return DayPlanDraft(plan: plan)
    }

    func save(_ draft: DayPlanDraft) async throws {
        _ = try repository.save(draft)
        try refreshPlans()
        refreshActiveState()
        await reconcileNotifications(showingErrors: true)

        if !hasCompletedOnboarding {
            hasCompletedOnboarding = true
        }
        if !preferences.bool(forKey: PreferenceKey.notificationPrimerSeen),
           notificationStatus == .notDetermined,
           hasConfiguredPlan {
            if editingWeekday == nil {
                isShowingNotificationPrimer = true
            } else {
                shouldPresentNotificationPrimerAfterEditor = true
            }
        }
    }

    func removePlan(for weekday: Weekday) async throws {
        _ = try repository.removePlan(for: weekday)
        try refreshPlans()
        refreshActiveState()
        await reconcileNotifications(showingErrors: true)
    }

    func requestNotifications() async {
        guard hasConfiguredPlan else {
            alertMessage = "Planlegg minst én Happy Hour før du slår på startvarsler."
            return
        }

        do {
            _ = try await notificationScheduler.requestAuthorization()
            preferences.set(true, forKey: PreferenceKey.notificationPrimerSeen)
            await refreshNotificationStateAndReconcile()
            isShowingNotificationPrimer = false
        } catch {
            alertMessage = "Varslingstillatelsen kunne ikke oppdateres. \(error.localizedDescription)"
        }
    }

    func skipNotificationPrimer() {
        preferences.set(true, forKey: PreferenceKey.notificationPrimerSeen)
        isShowingNotificationPrimer = false
    }

    func queueCalendarAfterEditorDismiss(for weekday: Weekday) {
        pendingCalendarWeekday = weekday
    }

    func editorDidDismiss() {
        editingWeekday = nil

        if shouldPresentNotificationPrimerAfterEditor {
            shouldPresentNotificationPrimerAfterEditor = false
            isShowingNotificationPrimer = true
        } else {
            presentPendingCalendarIfPossible()
        }
    }

    func notificationPrimerDidDismiss() {
        isShowingNotificationPrimer = false
        presentPendingCalendarIfPossible()
    }

    func sceneBecameActive() async {
        do {
            try refreshPlans()
        } catch {
            alertMessage = friendlyMessage(for: error)
        }
        refreshActiveState()
        await refreshNotificationStateAndReconcile()
    }

    func significantTimeDidChange() async {
        selectedWeekday = Weekday.current(
            in: calendarProvider.calendar,
            at: clock.now
        )
        refreshActiveState()
        await reconcileNotifications(showingErrors: false)
    }

    func addToCalendar(_ plan: DayPlanModel) {
        guard plan.isConfigured, calendarPresentation == nil else { return }

        do {
            let store = EKEventStore()
            let event = try calendarEventBuilder.makeEvent(
                for: plan.snapshot,
                in: store,
                relativeTo: clock.now,
                calendar: calendarProvider.calendar
            )
            calendarPresentation = CalendarPresentation(event: event, store: store)
        } catch {
            alertMessage = "Kalenderhendelsen kunne ikke klargjøres. \(friendlyMessage(for: error))"
        }
    }

    private func presentPendingCalendarIfPossible() {
        guard
            !isShowingNotificationPrimer,
            calendarPresentation == nil,
            let weekday = pendingCalendarWeekday
        else {
            return
        }

        pendingCalendarWeekday = nil

        guard let plan = plans.first(where: { $0.weekday == weekday && $0.isConfigured }) else {
            alertMessage = "Planen må lagres før den kan legges til i Kalender."
            return
        }

        addToCalendar(plan)
    }

    func finishCalendarEditing(with result: CalendarEventEditResult) {
        calendarPresentation = nil

        guard result == .saved else { return }
        showTransientMessage(
            "Lagt til én gang – senere endringer synkroniseres ikke"
        )
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }

    func clearAlert() {
        alertMessage = nil
    }

    private func refreshPlans() throws {
        plans = try repository.fetchAllPlans()
    }

    private func refreshNotificationStateAndReconcile() async {
        notificationStatus = await notificationScheduler.authorizationStatus()
        await reconcileNotifications(showingErrors: false)
        notificationStatus = await notificationScheduler.authorizationStatus()
    }

    private func reconcileNotifications(showingErrors: Bool) async {
        do {
            let snapshots = plans.map(\.snapshot)
            let result = try await notificationScheduler.reconcile(snapshots)
            notificationStatus = result.authorizationStatus
        } catch {
            if showingErrors {
                alertMessage = "Planen ble lagret, men varselet kunne ikke oppdateres. "
                    + "Appen prøver igjen neste gang den åpnes."
            }
        }
    }

    func refreshActiveState() {
        let now = clock.now
        let calendar = calendarProvider.calendar

        activeWeekdays = Set(
            plans.lazy
            .filter(\.isConfigured)
            .compactMap { plan -> Weekday? in
                guard
                    let occurrence = try? self.scheduleResolver.currentOrNextOccurrence(
                        for: plan.snapshot,
                        relativeTo: now,
                        calendar: calendar
                    ),
                    occurrence.contains(now)
                else {
                    return nil
                }
                return plan.weekday
            }
        )
    }

    private func installConfiguredFixture() throws {
        for (index, weekday) in Weekday.allCases.enumerated() {
            let activity = ActivityDraft(
                name: "Rolig aktivitet \(index + 1)",
                details: index.isMultiple(of: 2) ? "Et lite tips for dagen." : "",
                colorToken: .forPosition(index)
            )
            _ = try repository.save(
                DayPlanDraft(
                    weekday: weekday,
                    isConfigured: true,
                    activities: [activity]
                )
            )
        }
    }

    private func installBeerMugFixture() throws {
        let fixtures: [(weekday: Weekday, activities: [String])] = [
            (
                .monday,
                ["Lese"]
            ),
            (
                .tuesday,
                ["Male", "Høre på musikk", "Skrive"]
            ),
            (
                .thursday,
                [
                    "Spille gitar",
                    "Lese",
                    "Gå tur",
                    "Lære spansk",
                    "Ringe en venn",
                ]
            ),
            (
                .sunday,
                [
                    "Tegne",
                    "Lage middag",
                    "Fotografere",
                    "Lese dikt",
                    "Spille piano",
                    "Gå en tur",
                    "Skrive dagbok",
                    "Lære noe nytt",
                    "Ringe familien",
                    "Planlegge uken",
                ]
            ),
        ]

        for fixture in fixtures {
            let activities = fixture.activities.enumerated().map { index, name in
                ActivityDraft(
                    name: name,
                    details: index == 0 ? "Et lite tips for aktiviteten." : "",
                    colorToken: .forPosition(index)
                )
            }
            _ = try repository.save(
                DayPlanDraft(
                    weekday: fixture.weekday,
                    isConfigured: true,
                    startMinuteOfDay: 18 * 60,
                    endMinuteOfDay: 19 * 60,
                    activities: activities
                )
            )
        }
    }

    private func showTransientMessage(_ message: String) {
        transientMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            if self?.transientMessage == message {
                self?.transientMessage = nil
            }
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

@MainActor
final class CalendarPresentation: Identifiable {
    let id = UUID()
    let event: EKEvent
    let store: EKEventStore

    init(event: EKEvent, store: EKEventStore) {
        self.event = event
        self.store = store
    }
}
