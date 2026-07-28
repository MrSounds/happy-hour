import XCTest

@MainActor
final class HappyHourUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingCanBeSkipped() {
        let app = makeApp()
        app.launch()

        // Onboarding is implemented as a ScrollView, so query its concrete
        // accessibility element type rather than assuming an `otherElement`.
        let onboarding = app.scrollViews["onboarding"]
        XCTAssertTrue(onboarding.waitForExistence(timeout: 10))

        let skipButton = app.buttons["onboarding-skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3))
        skipButton.tap()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(onboarding.exists)
    }

    func testConfiguredFixtureSupportsEveryWeekdayButton() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))

        for weekdayISO in 1...7 {
            let weekdayButton = app.buttons["weekday-\(weekdayISO)"]
            XCTAssertTrue(
                weekdayButton.waitForExistence(timeout: 3),
                "Mangler dagknapp for ISO-ukedag \(weekdayISO)"
            )

            weekdayButton.tap()

            let selected = NSPredicate(format: "value == %@", "Valgt")
            expectation(
                for: selected,
                evaluatedWith: weekdayButton,
                handler: nil
            )
            waitForExpectations(timeout: 3)

            XCTAssertTrue(
                dayPage(weekdayISO, in: app).waitForExistence(timeout: 3),
                "Mangler dagside for ISO-ukedag \(weekdayISO)"
            )
        }
    }

    func testConfiguredPagerCanSwipeFromMondayToTuesday() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        selectWeekday(1, in: app)

        let mondayPage = dayPage(1, in: app)
        XCTAssertTrue(mondayPage.waitForExistence(timeout: 3))
        mondayPage.swipeLeft()

        XCTAssertTrue(dayPage(2, in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(waitForSelectedWeekday(2, in: app))
    }

    func testBeerMugFixtureShowsHappyHourWithFiveActivitiesOnThursday() {
        let app = makeApp(beerMugFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))

        let title = app.staticTexts["main-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertEqual(title.label, "Happy Hour")
        XCTAssertTrue(waitForSelectedWeekday(4, in: app))

        let page = dayPage(4, in: app)
        XCTAssertTrue(page.waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(
                    NSPredicate(
                        format: "label == %@",
                        "Aktiviteter i ølglasset"
                    )
                )
                .firstMatch
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(waitForActivityCount(5, in: app))

        for name in [
            "Spille gitar",
            "Lese",
            "Gå tur",
            "Lære spansk",
            "Ringe en venn",
        ] {
            XCTAssertTrue(
                app.buttons["Vis detaljer for \(name)"]
                    .waitForExistence(timeout: 3),
                "Mangler aktiviteten \(name)"
            )
        }
    }

    func testBeerMugFixtureCoversOneThreeFiveAndTenActivityLayouts() {
        let app = makeApp(beerMugFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))

        for (weekdayISO, expectedCount) in [(1, 1), (2, 3), (4, 5), (7, 10)] {
            selectWeekday(weekdayISO, in: app)
            let page = dayPage(weekdayISO, in: app)
            XCTAssertTrue(page.exists)
            XCTAssertTrue(
                waitForActivityCount(expectedCount, in: app),
                "Forventet \(expectedCount) aktivitetsrader på ISO-ukedag \(weekdayISO)"
            )
        }
    }

    func testCalendarActionLivesInsideTheEditorInsteadOfTheMainScreen() {
        let app = makeApp(beerMugFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Legg til i kalender"].exists)

        let editButton = app.buttons["Rediger torsdag"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        XCTAssertTrue(editor(in: app).waitForExistence(timeout: 5))
        let editorList = app.collectionViews.firstMatch
        XCTAssertTrue(editorList.waitForExistence(timeout: 3))

        let calendarButton = app.buttons["Legg til i kalender"]
        XCTAssertTrue(scrollToHittable(calendarButton, in: editorList))
        XCTAssertEqual(calendarButton.label, "Legg til i kalender")
    }

    func testActivityDetailsShowNotesAndEmptyState() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))

        selectWeekday(1, in: app)
        let notedActivity = app.buttons["Vis detaljer for Rolig aktivitet 1"]
        XCTAssertTrue(notedActivity.waitForExistence(timeout: 3))
        notedActivity.tap()

        XCTAssertTrue(
            app.navigationBars["Aktivitetsdetaljer"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["Et lite tips for dagen."].exists)
        app.buttons["Ferdig"].tap()

        selectWeekday(2, in: app)
        let activityWithoutNotes = app.buttons["Vis detaljer for Rolig aktivitet 2"]
        XCTAssertTrue(activityWithoutNotes.waitForExistence(timeout: 3))
        activityWithoutNotes.tap()

        XCTAssertTrue(
            app.staticTexts["Ingen notater lagt til."].waitForExistence(timeout: 5)
        )
        app.buttons["Ferdig"].tap()
        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 5))
    }

    func testSettingsShowsLocalPrivacyInformationAndCanClose() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        let settingsButton = app.buttons["Innstillinger"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        let settings = app.descendants(matching: .any)["settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.swipeUp()

        XCTAssertTrue(
            app.staticTexts["Lagres på denne iPhonen"].waitForExistence(timeout: 3)
        )

        let calendarPrivacyCopy = app.staticTexts["Kalender er en engangshandling"]
        if !calendarPrivacyCopy.exists {
            settings.swipeUp()
        }
        XCTAssertTrue(calendarPrivacyCopy.waitForExistence(timeout: 3))

        let doneButton = app.buttons["Ferdig"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(settings.exists)
    }

    func testConfiguredPlanEditorCanCancelAndSave() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))

        let editButton = app.buttons["edit-day-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        XCTAssertTrue(editor(in: app).waitForExistence(timeout: 5))
        let cancelButton = app.buttons["editor-cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        cancelButton.tap()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 5))

        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        XCTAssertTrue(editor(in: app).waitForExistence(timeout: 5))
        let saveButton = app.buttons["editor-save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(editor(in: app).exists)
    }

    func testEditorAllowsTenActivitiesAndBlocksTheEleventh() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        selectWeekday(1, in: app)
        app.buttons["edit-day-button"].tap()

        let dayEditor = editor(in: app)
        XCTAssertTrue(dayEditor.waitForExistence(timeout: 5))
        let editorList = app.collectionViews.firstMatch
        XCTAssertTrue(editorList.waitForExistence(timeout: 3))

        let addButton = app.buttons["add-activity-button"]
        for activityCount in 2...10 {
            XCTAssertTrue(
                scrollToHittable(addButton, in: editorList),
                "Knappen for ny aktivitet var ikke tilgjengelig før aktivitet \(activityCount)"
            )
            XCTAssertTrue(
                addButton.isEnabled,
                "Knappen ble deaktivert før aktivitet \(activityCount)"
            )
            addButton.tap()
        }

        XCTAssertTrue(scrollToHittable(addButton, in: editorList))
        XCTAssertFalse(addButton.isEnabled)
        XCTAssertTrue(
            app.staticTexts["Du har lagt til maksimalt ti aktiviteter."]
                .waitForExistence(timeout: 3)
        )

        app.buttons["editor-cancel"].tap()
        let discardButton = app.buttons["Forkast"]
        XCTAssertTrue(discardButton.waitForExistence(timeout: 3))
        discardButton.tap()
        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 5))
    }

    func testEditorPersistsRenamedActivity() {
        let app = makeApp(configuredFixture: true)
        app.launch()

        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))
        selectWeekday(1, in: app)
        app.buttons["edit-day-button"].tap()
        XCTAssertTrue(editor(in: app).waitForExistence(timeout: 5))

        let nameField = app.textFields
            .matching(NSPredicate(format: "label == %@", "Aktivitetsnavn"))
            .firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText(" oppdatert")

        let keyboardDone = app.keyboards.buttons["Done"]
        if keyboardDone.exists {
            keyboardDone.tap()
        }

        let saveButton = app.buttons["editor-save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
        XCTAssertTrue(mainExperience(in: app).waitForExistence(timeout: 10))

        let detailsButton = app.buttons[
            "Vis detaljer for Rolig aktivitet 1 oppdatert"
        ]
        XCTAssertTrue(detailsButton.waitForExistence(timeout: 5))
        detailsButton.tap()
        XCTAssertTrue(
            app.staticTexts["Et lite tips for dagen."]
                .waitForExistence(timeout: 5)
        )
    }

    private func makeApp(
        configuredFixture: Bool = false,
        beerMugFixture: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        if configuredFixture {
            app.launchArguments.append("-configuredFixture")
        }
        if beerMugFixture {
            app.launchArguments.append("-beerMugFixture")
        }
        return app
    }

    private func mainExperience(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts["main-title"]
    }

    private func editor(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["day-editor"]
    }

    private func selectWeekday(_ weekdayISO: Int, in app: XCUIApplication) {
        let button = app.buttons["weekday-\(weekdayISO)"]
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.tap()
        XCTAssertTrue(waitForSelectedWeekday(weekdayISO, in: app))
        XCTAssertTrue(dayPage(weekdayISO, in: app).waitForExistence(timeout: 3))
    }

    private func waitForSelectedWeekday(
        _ weekdayISO: Int,
        in app: XCUIApplication
    ) -> Bool {
        let button = app.buttons["weekday-\(weekdayISO)"]
        let predicate = NSPredicate(format: "value == %@", "Valgt")
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: button
        )
        return XCTWaiter.wait(for: [expectation], timeout: 3) == .completed
    }

    private func waitForActivityCount(
        _ expectedCount: Int,
        in app: XCUIApplication,
        timeout: TimeInterval = 3
    ) -> Bool {
        let activityButtons = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "activity-")
        )
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if activityButtons.count == expectedCount {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return activityButtons.count == expectedCount
    }

    private func dayPage(
        _ weekdayISO: Int,
        in app: XCUIApplication
    ) -> XCUIElement {
        let names = [
            "Mandag",
            "Tirsdag",
            "Onsdag",
            "Torsdag",
            "Fredag",
            "Lørdag",
            "Søndag",
        ]
        let name = names[weekdayISO - 1]
        return app.scrollViews.matching(
            NSPredicate(
                format: "label == %@",
                "\(name), side \(weekdayISO) av 7"
            )
        )
        .firstMatch
    }

    private func scrollToHittable(
        _ element: XCUIElement,
        in scrollView: XCUIElement,
        maximumSwipes: Int = 8
    ) -> Bool {
        for _ in 0..<maximumSwipes where !element.isHittable {
            scrollView.swipeUp()
        }
        return element.isHittable
    }
}
