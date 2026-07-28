import EventKit
import Foundation
import UserNotifications
import XCTest
@testable import HappyHour

final class SystemServicesTests: XCTestCase {
    func testWeekdayMappingUsesISOAndFoundationConventions() {
        XCTAssertEqual(Weekday.monday.isoWeekday, 1)
        XCTAssertEqual(Weekday.monday.foundationWeekday, 2)
        XCTAssertEqual(Weekday.sunday.isoWeekday, 7)
        XCTAssertEqual(Weekday.sunday.foundationWeekday, 1)
    }

    func testResolverReturnsActiveSameDayOccurrence() throws {
        let calendar = makeCalendar(timeZoneID: "UTC")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 27,
            hour: 18,
            minute: 30,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 19 * 60
        )

        let occurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.day, from: occurrence.start), 27)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.start), 18)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.end), 19)
        XCTAssertTrue(occurrence.contains(now))
    }

    func testResolverReturnsNextWeekAfterOccurrenceEnds() throws {
        let calendar = makeCalendar(timeZoneID: "UTC")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 27,
            hour: 20,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 19 * 60
        )

        let occurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.day, from: occurrence.start), 3)
        XCTAssertEqual(calendar.component(.month, from: occurrence.start), 8)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.start), 18)
    }

    func testResolverRecognizesActiveOvernightOccurrence() throws {
        let calendar = makeCalendar(timeZoneID: "UTC")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 29,
            hour: 0,
            minute: 10,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .tuesday,
            startMinute: 23 * 60 + 30,
            endMinute: 30,
            endDayOffset: 1
        )

        let occurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.day, from: occurrence.start), 28)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.start), 23)
        XCTAssertEqual(calendar.component(.day, from: occurrence.end), 29)
        XCTAssertEqual(calendar.component(.minute, from: occurrence.end), 30)
        XCTAssertTrue(occurrence.contains(now))
    }

    func testResolverCarriesSundayOccurrenceIntoMonday() throws {
        let calendar = makeCalendar(timeZoneID: "UTC")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 27,
            hour: 0,
            minute: 30,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .sunday,
            startMinute: 23 * 60 + 30,
            endMinute: 60,
            endDayOffset: 1
        )

        let occurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.weekday, from: occurrence.start), 1)
        XCTAssertEqual(calendar.component(.day, from: occurrence.start), 26)
        XCTAssertEqual(calendar.component(.weekday, from: occurrence.end), 2)
        XCTAssertEqual(calendar.component(.day, from: occurrence.end), 27)
        XCTAssertTrue(occurrence.contains(now))
    }

    func testResolverMovesMissingSpringForwardStartToNextValidTime() throws {
        let calendar = makeCalendar(timeZoneID: "Europe/Oslo")
        let now = makeDate(
            year: 2026,
            month: 3,
            day: 28,
            hour: 12,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .sunday,
            startMinute: 2 * 60 + 30,
            endMinute: 3 * 60 + 30
        )

        let occurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.day, from: occurrence.start), 29)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.start), 3)
        XCTAssertEqual(calendar.component(.minute, from: occurrence.start), 0)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.end), 3)
        XCTAssertEqual(calendar.component(.minute, from: occurrence.end), 30)
    }

    func testResolverUsesFirstRepeatedStartDuringFallBack() throws {
        let calendar = makeCalendar(timeZoneID: "America/Los_Angeles")
        let now = makeDate(
            year: 2026,
            month: 10,
            day: 31,
            hour: 12,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .sunday,
            startMinute: 60 + 30,
            endMinute: 2 * 60 + 30
        )

        let occurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.day, from: occurrence.start), 1)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.start), 1)
        XCTAssertEqual(calendar.component(.minute, from: occurrence.start), 30)
        XCTAssertEqual(calendar.component(.hour, from: occurrence.end), 2)
        XCTAssertEqual(calendar.component(.minute, from: occurrence.end), 30)
        XCTAssertEqual(occurrence.end.timeIntervalSince(occurrence.start), 7_200)
    }

    func testResolverReevaluatesWallClockInSuppliedTimeZone() throws {
        let utcCalendar = makeCalendar(timeZoneID: "UTC")
        let losAngelesCalendar = makeCalendar(timeZoneID: "America/Los_Angeles")
        let instant = makeDate(
            year: 2026,
            month: 7,
            day: 27,
            hour: 20,
            calendar: utcCalendar
        )
        let schedule = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 19 * 60
        )

        let utcOccurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: instant,
            calendar: utcCalendar
        )
        let losAngelesOccurrence = try ScheduleResolver().currentOrNextOccurrence(
            for: schedule,
            relativeTo: instant,
            calendar: losAngelesCalendar
        )

        XCTAssertEqual(utcCalendar.component(.day, from: utcOccurrence.start), 3)
        XCTAssertEqual(
            losAngelesCalendar.component(.day, from: losAngelesOccurrence.start),
            27
        )
        XCTAssertEqual(
            losAngelesCalendar.component(.hour, from: losAngelesOccurrence.start),
            18
        )
        XCTAssertNotEqual(utcOccurrence.start, losAngelesOccurrence.start)
    }

    func testResolverRejectsInvalidNominalDurations() {
        let resolver = ScheduleResolver()
        let tooShort = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 18 * 60 + 59
        )
        let fullDay = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 18 * 60,
            endDayOffset: 1
        )

        XCTAssertThrowsError(try resolver.nominalDurationMinutes(for: tooShort))
        XCTAssertThrowsError(try resolver.nominalDurationMinutes(for: fullDay))
    }

    func testNotificationDescriptorUsesStableIdentifierAndOmitsDetails() {
        let schedule = makeSchedule(
            weekday: .tuesday,
            startMinute: 18 * 60 + 30,
            endMinute: 19 * 60 + 30,
            names: ["Run", "Shower", "Guitar", "Read"],
            details: "Private note"
        )

        let descriptor = NotificationScheduler.descriptor(for: schedule)

        XCTAssertEqual(descriptor.identifier, "happyhour.start.iso-2")
        XCTAssertEqual(descriptor.foundationWeekday, 3)
        XCTAssertEqual(descriptor.hour, 18)
        XCTAssertEqual(descriptor.minute, 30)
        XCTAssertEqual(descriptor.body, "Run, Shower, Guitar og 1 til")
        XCTAssertFalse(descriptor.body.contains("Private note"))

        let request = descriptor.makeRequest()
        let trigger = request.trigger as? UNCalendarNotificationTrigger
        XCTAssertEqual(trigger?.dateComponents.weekday, 3)
        XCTAssertEqual(trigger?.dateComponents.hour, 18)
        XCTAssertEqual(trigger?.dateComponents.minute, 30)
        XCTAssertEqual(trigger?.repeats, true)
        XCTAssertNotNil(request.content.sound)
        XCTAssertNil(request.content.badge)
        XCTAssertEqual(request.content.interruptionLevel, .active)
        XCTAssertEqual(
            request.content.userInfo[
                AppNotificationDelegate.weekdayUserInfoKey
            ] as? Int,
            2
        )
    }

    @MainActor
    func testNotificationDelegateRoutesOnlyValidISOWeekdays() {
        let delegate = AppNotificationDelegate()
        var routedWeekday: Weekday?
        delegate.install { weekday in
            routedWeekday = weekday
        }

        delegate.route(to: 7)
        XCTAssertEqual(routedWeekday, .sunday)

        delegate.route(to: 8)
        XCTAssertEqual(routedWeekday, .sunday)
    }

    @MainActor
    func testNotificationReconciliationReplacesOnlyManagedRequests() async throws {
        let client = FakeNotificationCenterClient(
            status: .authorized,
            pending: [
                "happyhour.start.iso-1",
                "happyhour.start.iso-7",
                "another-feature"
            ]
        )
        let scheduler = NotificationScheduler(client: client)
        let schedule = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 19 * 60
        )

        let result = try await scheduler.reconcile([schedule])

        XCTAssertEqual(result.scheduledIdentifiers, ["happyhour.start.iso-1"])
        XCTAssertEqual(
            result.removedIdentifiers,
            ["happyhour.start.iso-7"]
        )
        XCTAssertEqual(client.added.map(\.identifier), ["happyhour.start.iso-1"])
        XCTAssertTrue(client.pending.contains("another-feature"))
        XCTAssertEqual(
            client.pending.filter { $0.hasPrefix(NotificationScheduler.identifierPrefix) },
            ["happyhour.start.iso-1"]
        )
    }

    @MainActor
    func testNotificationAddFailurePreservesExistingManagedRequests() async {
        let client = FakeNotificationCenterClient(
            status: .authorized,
            pending: [
                "happyhour.start.iso-1",
                "happyhour.start.iso-2",
                "happyhour.start.iso-7"
            ]
        )
        client.addErrorIdentifier = "happyhour.start.iso-2"
        let scheduler = NotificationScheduler(client: client)
        let schedules = [
            makeSchedule(
                weekday: .monday,
                startMinute: 18 * 60,
                endMinute: 19 * 60
            ),
            makeSchedule(
                weekday: .tuesday,
                startMinute: 19 * 60,
                endMinute: 20 * 60
            ),
        ]

        do {
            _ = try await scheduler.reconcile(schedules)
            XCTFail("Expected the second notification add to fail")
        } catch {
            XCTAssertEqual(
                client.pending,
                [
                    "happyhour.start.iso-1",
                    "happyhour.start.iso-2",
                    "happyhour.start.iso-7"
                ]
            )
            XCTAssertTrue(client.removed.isEmpty)
        }
    }

    @MainActor
    func testDeniedNotificationStatusRemovesManagedRequests() async throws {
        let client = FakeNotificationCenterClient(
            status: .denied,
            pending: ["happyhour.start.iso-3", "another-feature"]
        )
        let scheduler = NotificationScheduler(client: client)

        let result = try await scheduler.reconcile([])

        XCTAssertEqual(result.authorizationStatus, .denied)
        XCTAssertEqual(result.removedIdentifiers, ["happyhour.start.iso-3"])
        XCTAssertTrue(client.added.isEmpty)
        XCTAssertEqual(client.pending, ["another-feature"])
    }

    @MainActor
    func testNotDeterminedNotificationStatusDoesNotSchedule() async throws {
        let client = FakeNotificationCenterClient(
            status: .notDetermined,
            pending: ["happyhour.start.iso-4"]
        )
        let scheduler = NotificationScheduler(client: client)

        let result = try await scheduler.reconcile([
            makeSchedule(
                weekday: .thursday,
                startMinute: 18 * 60,
                endMinute: 19 * 60
            ),
        ])

        XCTAssertEqual(result.authorizationStatus, .notDetermined)
        XCTAssertTrue(result.scheduledIdentifiers.isEmpty)
        XCTAssertTrue(client.added.isEmpty)
        XCTAssertTrue(client.pending.isEmpty)
    }

    @MainActor
    func testProvisionalNotificationStatusSchedules() async throws {
        let client = FakeNotificationCenterClient(status: .provisional, pending: [])
        let scheduler = NotificationScheduler(client: client)

        let result = try await scheduler.reconcile([
            makeSchedule(
                weekday: .friday,
                startMinute: 20 * 60 + 15,
                endMinute: 21 * 60 + 15
            ),
        ])

        XCTAssertEqual(result.authorizationStatus, .provisional)
        XCTAssertEqual(result.scheduledIdentifiers, ["happyhour.start.iso-5"])
        XCTAssertEqual(client.added.first?.hour, 20)
        XCTAssertEqual(client.added.first?.minute, 15)
    }

    func testCalendarDescriptorUsesCurrentOccurrenceAndActivityNamesOnly() throws {
        let calendar = makeCalendar(timeZoneID: "UTC")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 27,
            hour: 18,
            minute: 30,
            calendar: calendar
        )
        let schedule = makeSchedule(
            weekday: .monday,
            startMinute: 18 * 60,
            endMinute: 19 * 60,
            names: ["Run", "Read"],
            details: "Do not export this"
        )

        let descriptor = try CalendarEventBuilder().descriptor(
            for: schedule,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(descriptor.title, "Happy Hour")
        XCTAssertEqual(calendar.component(.hour, from: descriptor.startDate), 18)
        XCTAssertEqual(calendar.component(.hour, from: descriptor.endDate), 19)
        XCTAssertEqual(descriptor.notes, "• Run\n• Read")
        XCTAssertFalse(descriptor.notes?.contains("Do not export this") == true)
        XCTAssertEqual(descriptor.timeZone.secondsFromGMT(for: now), 0)
    }

    func testCalendarDescriptorUsesNextWeekAfterTodaysOccurrenceEnded() throws {
        let calendar = makeCalendar(timeZoneID: "UTC")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 27,
            hour: 20,
            calendar: calendar
        )
        let descriptor = try CalendarEventBuilder().descriptor(
            for: makeSchedule(
                weekday: .monday,
                startMinute: 18 * 60,
                endMinute: 19 * 60
            ),
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.month, from: descriptor.startDate), 8)
        XCTAssertEqual(calendar.component(.day, from: descriptor.startDate), 3)
        XCTAssertEqual(calendar.component(.hour, from: descriptor.startDate), 18)
        XCTAssertEqual(calendar.component(.hour, from: descriptor.endDate), 19)
    }

    @MainActor
    func testCalendarEventCrossesMidnightWithoutAlarmOrRecurrence() throws {
        let calendar = makeCalendar(timeZoneID: "Europe/Oslo")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 28,
            hour: 22,
            calendar: calendar
        )
        let store = EKEventStore()
        let event = try CalendarEventBuilder().makeEvent(
            for: makeSchedule(
                weekday: .tuesday,
                startMinute: 23 * 60 + 30,
                endMinute: 30,
                endDayOffset: 1,
                names: ["Read", "Walk"]
            ),
            in: store,
            relativeTo: now,
            calendar: calendar
        )

        XCTAssertEqual(calendar.component(.day, from: event.startDate), 28)
        XCTAssertEqual(calendar.component(.hour, from: event.startDate), 23)
        XCTAssertEqual(calendar.component(.day, from: event.endDate), 29)
        XCTAssertEqual(calendar.component(.minute, from: event.endDate), 30)
        XCTAssertEqual(event.notes, "• Read\n• Walk")
        XCTAssertTrue(event.alarms?.isEmpty ?? true)
        XCTAssertTrue(event.recurrenceRules?.isEmpty ?? true)
    }

    @MainActor
    func testNotificationPermissionIsNotRequestedWithoutAConfiguredPlan() async throws {
        let container = try HappyHourPersistence.makeContainer(inMemory: true)
        let client = FakeNotificationCenterClient(status: .notDetermined, pending: [])
        let model = AppModel(
            modelContainer: container,
            preferences: makePreferences(),
            notificationScheduler: NotificationScheduler(client: client)
        )

        await model.bootstrap()
        await model.requestNotifications()

        XCTAssertEqual(client.authorizationRequestCount, 0)
        XCTAssertNotNil(model.alertMessage)
    }

    @MainActor
    func testFirstSaveOffersNotificationPrimerAfterOnboardingWasSkipped() async throws {
        let container = try HappyHourPersistence.makeContainer(inMemory: true)
        let client = FakeNotificationCenterClient(status: .notDetermined, pending: [])
        let model = AppModel(
            modelContainer: container,
            preferences: makePreferences(),
            notificationScheduler: NotificationScheduler(client: client)
        )

        await model.bootstrap()
        model.skipOnboarding()
        try await model.save(
            DayPlanDraft(
                weekday: .monday,
                isConfigured: true,
                activities: [ActivityDraft(name: "Read")]
            )
        )

        XCTAssertTrue(model.isShowingNotificationPrimer)
        XCTAssertEqual(client.authorizationRequestCount, 0)
    }

    @MainActor
    func testNotificationFailureDoesNotRollBackSavedPlan() async throws {
        let container = try HappyHourPersistence.makeContainer(inMemory: true)
        let client = FakeNotificationCenterClient(status: .authorized, pending: [])
        client.addErrorIdentifier = "happyhour.start.iso-1"
        let model = AppModel(
            modelContainer: container,
            preferences: makePreferences(),
            notificationScheduler: NotificationScheduler(client: client)
        )
        await model.bootstrap()

        try await model.save(
            DayPlanDraft(
                weekday: .monday,
                isConfigured: true,
                activities: [ActivityDraft(name: "Read")]
            )
        )

        let saved = try XCTUnwrap(
            model.plans.first(where: { $0.weekday == .monday })
        )
        XCTAssertTrue(saved.isConfigured)
        XCTAssertEqual(saved.sortedActivities.map(\.name), ["Read"])
        XCTAssertNotNil(model.alertMessage)
    }

    @MainActor
    func testActiveStateIncludesOverlappingOvernightPlans() async throws {
        let calendar = makeCalendar(timeZoneID: "Europe/Oslo")
        let now = makeDate(
            year: 2026,
            month: 7,
            day: 29,
            hour: 0,
            minute: 30,
            calendar: calendar
        )
        let container = try HappyHourPersistence.makeContainer(inMemory: true)
        let repository = PlanRepository(modelContainer: container)
        try repository.seedWeekIfNeeded()
        try repository.save(
            DayPlanDraft(
                weekday: .tuesday,
                isConfigured: true,
                startMinuteOfDay: 23 * 60 + 30,
                endMinuteOfDay: 60,
                endDayOffset: 1,
                activities: [ActivityDraft(name: "Stargaze")]
            )
        )
        try repository.save(
            DayPlanDraft(
                weekday: .wednesday,
                isConfigured: true,
                startMinuteOfDay: 0,
                endMinuteOfDay: 2 * 60,
                activities: [ActivityDraft(name: "Read")]
            )
        )
        let client = FakeNotificationCenterClient(status: .notDetermined, pending: [])
        let model = AppModel(
            modelContainer: container,
            preferences: makePreferences(),
            notificationScheduler: NotificationScheduler(client: client),
            clock: FixedClock(now: now),
            calendarProvider: FixedCalendarProvider(calendar: calendar)
        )

        await model.bootstrap()

        XCTAssertEqual(model.activeWeekdays, [.tuesday, .wednesday])
    }

    private func makeSchedule(
        weekday: Weekday,
        startMinute: Int,
        endMinute: Int,
        endDayOffset: Int = 0,
        names: [String] = ["Read"],
        details: String? = nil
    ) -> DayPlanSnapshot {
        DayPlanSnapshot(
            id: UUID(),
            weekday: weekday,
            isConfigured: true,
            startMinuteOfDay: startMinute,
            endMinuteOfDay: endMinute,
            endDayOffset: endDayOffset,
            activities: names.enumerated().map { index, name in
                ActivitySnapshot(
                    id: UUID(),
                    name: name,
                    details: details,
                    sortIndex: index,
                    colorToken: .forPosition(index)
                )
            }
        )
    }

    private func makeCalendar(timeZoneID: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }

    private func makePreferences() -> UserDefaults {
        UserDefaults(suiteName: "HappyHourTests-\(UUID().uuidString)")!
    }
}

@MainActor
private final class FakeNotificationCenterClient: NotificationCenterClient {
    var status: AppNotificationAuthorizationStatus
    var pending: Set<String>
    var added: [LocalNotificationDescriptor] = []
    var removed: [[String]] = []
    var authorizationRequestResult = true
    var authorizationRequestCount = 0
    var addErrorIdentifier: String?

    init(status: AppNotificationAuthorizationStatus, pending: Set<String>) {
        self.status = status
        self.pending = pending
    }

    func authorizationStatus() async -> AppNotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        return authorizationRequestResult
    }

    func pendingRequestIdentifiers() async -> Set<String> {
        pending
    }

    func add(_ descriptor: LocalNotificationDescriptor) async throws {
        if descriptor.identifier == addErrorIdentifier {
            throw FakeNotificationError.addFailed
        }
        added.append(descriptor)
        pending.insert(descriptor.identifier)
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        removed.append(identifiers)
        pending.subtract(identifiers)
    }
}

private enum FakeNotificationError: Error {
    case addFailed
}
