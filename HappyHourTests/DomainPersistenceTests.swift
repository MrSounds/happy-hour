import SwiftData
import XCTest
@testable import HappyHour

final class DomainPersistenceTests: XCTestCase {
    func testWeekdayUsesISOValuesAndMapsFoundationWeekdays() {
        XCTAssertEqual(Weekday.allCases.map(\.rawValue), Array(1...7))
        XCTAssertEqual(Weekday.monday.foundationWeekday, 2)
        XCTAssertEqual(Weekday.sunday.foundationWeekday, 1)
        XCTAssertEqual(Weekday(foundationWeekday: 1), .sunday)
        XCTAssertEqual(Weekday(foundationWeekday: 7), .saturday)
        XCTAssertNil(Weekday(foundationWeekday: 0))
        XCTAssertNil(Weekday(isoWeekday: 8))
    }

    func testPaletteCyclesWithoutChangingSemanticTokens() {
        XCTAssertEqual(ActivityColorToken.forPosition(0), .dustySage)
        XCTAssertEqual(ActivityColorToken.forPosition(4), .softTerracotta)
        XCTAssertEqual(ActivityColorToken.forPosition(5), .dustySage)
        XCTAssertEqual(ActivityColorToken.forPosition(-1), .softTerracotta)
    }

    func testBeerMugMetricsReserveFiveFullSizeSlotsWhenEmpty() {
        let metrics = BeerMugFillMetrics(activityCount: 0)

        XCTAssertEqual(metrics.slotCount, 5)
        XCTAssertEqual(metrics.foamSlotCount, 5)
        XCTAssertEqual(metrics.rowHeight(in: 500), 100, accuracy: 0.001)
        XCTAssertEqual(metrics.foamHeight(in: 500), 500, accuracy: 0.001)
    }

    func testBeerMugMetricsAnchorOneFullSizeActivityBelowFourFoamSlots() {
        let metrics = BeerMugFillMetrics(activityCount: 1)

        XCTAssertEqual(metrics.slotCount, 5)
        XCTAssertEqual(metrics.foamSlotCount, 4)
        XCTAssertEqual(metrics.rowHeight(in: 500), 100, accuracy: 0.001)
        XCTAssertEqual(metrics.foamHeight(in: 500), 400, accuracy: 0.001)
    }

    func testBeerMugMetricsAnchorThreeFullSizeActivitiesBelowTwoFoamSlots() {
        let metrics = BeerMugFillMetrics(activityCount: 3)

        XCTAssertEqual(metrics.slotCount, 5)
        XCTAssertEqual(metrics.foamSlotCount, 2)
        XCTAssertEqual(metrics.rowHeight(in: 500), 100, accuracy: 0.001)
        XCTAssertEqual(metrics.foamHeight(in: 500), 200, accuracy: 0.001)
    }

    func testBeerMugMetricsUseTheFullInteriorForFiveActivities() {
        let metrics = BeerMugFillMetrics(activityCount: 5)

        XCTAssertEqual(metrics.slotCount, 5)
        XCTAssertEqual(metrics.foamSlotCount, 0)
        XCTAssertEqual(metrics.rowHeight(in: 500), 100, accuracy: 0.001)
        XCTAssertEqual(metrics.foamHeight(in: 500), 0, accuracy: 0.001)
    }

    func testBeerMugMetricsShrinkTenActivitiesEvenlyToFit() {
        let metrics = BeerMugFillMetrics(activityCount: 10)

        XCTAssertEqual(metrics.slotCount, 10)
        XCTAssertEqual(metrics.foamSlotCount, 0)
        XCTAssertEqual(metrics.rowHeight(in: 500), 50, accuracy: 0.001)
        XCTAssertEqual(metrics.foamHeight(in: 500), 0, accuracy: 0.001)
    }

    func testValidatorTrimsTextAndDerivesOvernightDuration() throws {
        let draft = DayPlanDraft(
            weekday: .friday,
            isConfigured: true,
            startMinuteOfDay: 23 * 60,
            endMinuteOfDay: 30,
            endDayOffset: 0,
            activities: [
                ActivityDraft(
                    name: "  Read a book \n",
                    details: "  Leave the phone outside.  ",
                    colorToken: .lavender
                ),
            ]
        )

        let normalized = try DayPlanValidator.normalized(draft)

        XCTAssertEqual(normalized.endDayOffset, 1)
        XCTAssertEqual(normalized.durationMinutes, 90)
        XCTAssertEqual(normalized.activities[0].name, "Read a book")
        XCTAssertEqual(normalized.activities[0].details, "Leave the phone outside.")
    }

    func testValidatorRejectsTwentyFourHourAndShortIntervals() {
        let activity = ActivityDraft(name: "Walk")
        let equalTimes = DayPlanDraft(
            weekday: .monday,
            isConfigured: true,
            startMinuteOfDay: 18 * 60,
            endMinuteOfDay: 18 * 60,
            activities: [activity]
        )
        let tooShort = DayPlanDraft(
            weekday: .monday,
            isConfigured: true,
            startMinuteOfDay: 18 * 60,
            endMinuteOfDay: 18 * 60 + 59,
            activities: [activity]
        )

        XCTAssertThrowsError(try DayPlanValidator.normalized(equalTimes)) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .invalidDuration(DayPlanDraft.minutesPerDay)
            )
        }
        XCTAssertThrowsError(try DayPlanValidator.normalized(tooShort)) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .invalidDuration(59)
            )
        }
    }

    func testValidatorEnforcesActivityCountAndNames() {
        let empty = DayPlanDraft(weekday: .tuesday, isConfigured: true)
        XCTAssertThrowsError(try DayPlanValidator.normalized(empty)) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .invalidActivityCount(0)
            )
        }

        let unnamed = DayPlanDraft(
            weekday: .tuesday,
            isConfigured: true,
            activities: [ActivityDraft(name: " \n ")]
        )
        XCTAssertThrowsError(try DayPlanValidator.normalized(unnamed)) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .emptyActivityName(index: 0)
            )
        }

        let eleven = DayPlanDraft(
            weekday: .tuesday,
            isConfigured: true,
            activities: (0..<11).map { ActivityDraft(name: "Activity \($0)") }
        )
        XCTAssertThrowsError(try DayPlanValidator.normalized(eleven)) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .invalidActivityCount(11)
            )
        }
    }

    func testValidatorAcceptsExactTextAndActivityLimitsWithDuplicateNames() throws {
        let fortyCharacterName = String(repeating: "å", count: 40)
        let fiveHundredCharacterDetails = String(repeating: "x", count: 500)
        var activities = (0..<10).map { index in
            ActivityDraft(name: "Read", colorToken: .forPosition(index))
        }
        activities[0].name = fortyCharacterName
        activities[0].details = fiveHundredCharacterDetails

        let normalized = try DayPlanValidator.normalized(
            DayPlanDraft(
                weekday: .tuesday,
                isConfigured: true,
                activities: activities
            )
        )

        XCTAssertEqual(normalized.activities.count, 10)
        XCTAssertEqual(normalized.activities[0].name.count, 40)
        XCTAssertEqual(normalized.activities[0].details.count, 500)
        XCTAssertEqual(normalized.activities.filter { $0.name == "Read" }.count, 9)
    }

    func testValidatorRejectsTextPastExactLimits() {
        let longName = ActivityDraft(name: String(repeating: "å", count: 41))
        let longDetails = ActivityDraft(
            name: "Read",
            details: String(repeating: "x", count: 501)
        )

        XCTAssertThrowsError(
            try DayPlanValidator.normalized(
                DayPlanDraft(
                    weekday: .wednesday,
                    isConfigured: true,
                    activities: [longName]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .activityNameTooLong(index: 0, limit: 40)
            )
        }
        XCTAssertThrowsError(
            try DayPlanValidator.normalized(
                DayPlanDraft(
                    weekday: .wednesday,
                    isConfigured: true,
                    activities: [longDetails]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? DayPlanValidationError,
                .activityDetailsTooLong(index: 0, limit: 500)
            )
        }
    }

    func testDraftStartChangePreservesNominalDurationAcrossMidnight() {
        var draft = DayPlanDraft(
            weekday: .wednesday,
            isConfigured: true,
            activities: [ActivityDraft(name: "Guitar")]
        )

        draft.setStartMinuteOfDay(23 * 60 + 30)

        XCTAssertEqual(draft.startMinuteOfDay, 23 * 60 + 30)
        XCTAssertEqual(draft.endMinuteOfDay, 30)
        XCTAssertEqual(draft.endDayOffset, 1)
        XCTAssertEqual(draft.durationMinutes, 60)
    }

    @MainActor
    func testNewEditorDoesNotReportChangesBeforeTheUserEdits() {
        let model = DayEditorModel(
            draft: DayPlanDraft(weekday: .monday),
            onSave: { _ in }
        )

        XCTAssertFalse(model.hasUnsavedChanges)

        model.draft.activities[0].name = "Read"

        XCTAssertTrue(model.hasUnsavedChanges)
    }

    @MainActor
    func testEditorRetainsDraftWhenSaveHandlerFails() async {
        let model = DayEditorModel(
            draft: DayPlanDraft(weekday: .monday),
            onSave: { _ in throw DomainTestError.saveFailed }
        )
        model.draft.activities[0].name = "Read"
        let draftBeforeSave = model.draft

        let didSave = await model.save()

        XCTAssertFalse(didSave)
        XCTAssertEqual(model.draft, draftBeforeSave)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isSaving)
    }

    @MainActor
    func testSeedingIsIdempotentAndCreatesExactlySevenOrderedDays() throws {
        let (container, repository) = try makeRepository()
        _ = container

        let first = try repository.seedWeekIfNeeded()
        let firstIDs = first.map(\.id)
        let second = try repository.seedWeekIfNeeded()

        XCTAssertEqual(first.count, 7)
        XCTAssertEqual(second.count, 7)
        XCTAssertEqual(second.map(\.weekday), Weekday.allCases)
        XCTAssertEqual(second.map(\.id), firstIDs)
        XCTAssertTrue(second.allSatisfy { !$0.isConfigured })
    }

    @MainActor
    func testSavePersistsNormalizedActivitiesOrderAndStableColors() throws {
        let (container, repository) = try makeRepository()
        _ = container
        try repository.seedWeekIfNeeded()

        let firstID = UUID()
        let secondID = UUID()
        let initial = DayPlanDraft(
            weekday: .monday,
            isConfigured: true,
            startMinuteOfDay: 9 * 60,
            endMinuteOfDay: 10 * 60 + 30,
            activities: [
                ActivityDraft(
                    id: firstID,
                    name: "  Run ",
                    details: "",
                    colorToken: .dustySage
                ),
                ActivityDraft(
                    id: secondID,
                    name: "Cold shower",
                    details: "  Two minutes  ",
                    colorToken: .blueGrey
                ),
            ]
        )

        let saved = try repository.save(initial)

        XCTAssertTrue(saved.isConfigured)
        XCTAssertEqual(saved.durationMinutes, 90)
        XCTAssertEqual(saved.sortedActivities.map(\.id), [firstID, secondID])
        XCTAssertEqual(saved.sortedActivities.map(\.name), ["Run", "Cold shower"])
        XCTAssertNil(saved.sortedActivities[0].details)
        XCTAssertEqual(saved.sortedActivities[1].details, "Two minutes")

        var reordered = DayPlanDraft(plan: saved)
        reordered.activities.swapAt(0, 1)
        let resaved = try repository.save(reordered)

        XCTAssertEqual(resaved.sortedActivities.map(\.id), [secondID, firstID])
        XCTAssertEqual(
            resaved.sortedActivities.map(\.colorToken),
            [.blueGrey, .dustySage]
        )
        XCTAssertEqual(resaved.snapshot.activities.map(\.id), [secondID, firstID])
    }

    @MainActor
    func testSavedPlanReloadsThroughAFreshModelContext() throws {
        let container = try HappyHourPersistence.makeContainer(inMemory: true)
        let repository = PlanRepository(modelContainer: container)
        try repository.seedWeekIfNeeded()
        try repository.save(
            DayPlanDraft(
                weekday: .friday,
                isConfigured: true,
                startMinuteOfDay: 21 * 60,
                endMinuteOfDay: 23 * 60,
                activities: [
                    ActivityDraft(name: "Walk", colorToken: .dustySage),
                    ActivityDraft(name: "Read", colorToken: .blueGrey),
                ]
            )
        )

        let reloadedRepository = PlanRepository(
            modelContext: ModelContext(container)
        )
        let reloaded = try XCTUnwrap(reloadedRepository.plan(for: .friday))

        XCTAssertTrue(reloaded.isConfigured)
        XCTAssertEqual(reloaded.startMinuteOfDay, 21 * 60)
        XCTAssertEqual(reloaded.endMinuteOfDay, 23 * 60)
        XCTAssertEqual(reloaded.sortedActivities.map(\.name), ["Walk", "Read"])
        XCTAssertEqual(
            reloaded.sortedActivities.map(\.colorToken),
            [.dustySage, .blueGrey]
        )
    }

    @MainActor
    func testInvalidDraftDoesNotMutatePersistedPlan() throws {
        let (container, repository) = try makeRepository()
        _ = container
        try repository.seedWeekIfNeeded()

        let valid = DayPlanDraft(
            weekday: .thursday,
            isConfigured: true,
            activities: [ActivityDraft(name: "Meditate", colorToken: .lavender)]
        )
        try repository.save(valid)

        var invalid = valid
        invalid.activities[0].name = "   "
        XCTAssertThrowsError(try repository.save(invalid))

        let reloaded = try XCTUnwrap(repository.plan(for: .thursday))
        XCTAssertEqual(reloaded.sortedActivities.map(\.name), ["Meditate"])
        XCTAssertTrue(reloaded.isConfigured)
    }

    @MainActor
    func testRemovingPlanResetsFixedSlotAndDeletesActivities() throws {
        let (container, repository) = try makeRepository()
        _ = container
        try repository.seedWeekIfNeeded()
        try repository.save(
            DayPlanDraft(
                weekday: .sunday,
                isConfigured: true,
                startMinuteOfDay: 23 * 60,
                endMinuteOfDay: 60,
                endDayOffset: 1,
                activities: [ActivityDraft(name: "Stargaze")]
            )
        )

        let removed = try repository.removePlan(for: .sunday)

        XCTAssertFalse(removed.isConfigured)
        XCTAssertEqual(removed.startMinuteOfDay, 18 * 60)
        XCTAssertEqual(removed.endMinuteOfDay, 19 * 60)
        XCTAssertEqual(removed.endDayOffset, 0)
        XCTAssertTrue(removed.activities.isEmpty)
        XCTAssertEqual(try repository.fetchAllPlans().count, 7)
    }

    @MainActor
    private func makeRepository() throws -> (ModelContainer, PlanRepository) {
        let container = try HappyHourPersistence.makeContainer(inMemory: true)
        return (container, PlanRepository(modelContainer: container))
    }
}

private enum DomainTestError: Error {
    case saveFailed
}
