//
//  Swift_LearnUITests.swift
//  Swift LearnUITests
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import XCTest

final class Swift_LearnUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testIntroStartsLearningJourney() throws {
        let firstLesson = try XCTUnwrap(loadLessonExpectations().first)
        let app = launchApp(skipIntro: false)

        let intro = app.descendants(matching: .any)["intro-screen"].firstMatch
        XCTAssertTrue(intro.waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.descendants(matching: .any)["intro-step-1"].firstMatch
                .waitForExistence(timeout: 5)
        )

        let next = app.buttons["intro-next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        activate(next)
        XCTAssertTrue(
            app.descendants(matching: .any)["intro-step-2"].firstMatch
                .waitForExistence(timeout: 5)
        )

        let secondNext = app.buttons["intro-next"].firstMatch
        XCTAssertTrue(secondNext.waitForExistence(timeout: 5))
        activate(secondNext)
        XCTAssertTrue(
            app.descendants(matching: .any)["intro-step-3"].firstMatch
                .waitForExistence(timeout: 5)
        )

        let startLearning = app.buttons["intro-start-learning"].firstMatch
        XCTAssertTrue(startLearning.waitForExistence(timeout: 5))
        activate(startLearning)

        let firstLessonButton = app.buttons[
            "start-lesson-\(firstLesson.id)"
        ].firstMatch
        XCTAssertTrue(firstLessonButton.waitForExistence(timeout: 15))
        XCTAssertFalse(intro.exists)
    }

    @MainActor
    func testCompletesFirstLessonAndUpdatesProgress() throws {
        let lessonExpectations = try loadLessonExpectations()
        let firstLesson = try XCTUnwrap(lessonExpectations.first)
        let secondLesson = try XCTUnwrap(lessonExpectations.dropFirst().first)
        let app = launchApp()

        let firstStart = app.buttons[
            "start-lesson-\(firstLesson.id)"
        ].firstMatch
        XCTAssertTrue(firstStart.waitForExistence(timeout: 15))

        let secondStart = app.buttons["start-lesson-\(secondLesson.id)"].firstMatch
        XCTAssertTrue(secondStart.waitForExistence(timeout: 5))
        XCTAssertFalse(secondStart.isEnabled)

        activate(firstStart)

        XCTAssertTrue(app.staticTexts["lesson-instruction"].waitForExistence(timeout: 5))
        let lessonTitle = app.descendants(matching: .any)["lesson-title"].firstMatch
        XCTAssertTrue(lessonTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts[firstLesson.title].firstMatch.waitForExistence(timeout: 5)
        )

        let choice = app.buttons["choice-\(firstLesson.correctChoiceID)"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        select(
            choice,
            firstChoice: app.buttons["choice-\(try XCTUnwrap(firstLesson.choices.first).id)"],
            choiceIndex: firstLesson.correctChoiceIndex
        )

        let submit = app.buttons["submit-answer"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        activate(submit)

        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .waitForExistence(timeout: 5)
        )
        assertSummary(
            app.staticTexts["lesson-progress-summary"].firstMatch,
            equals: "1 of \(lessonExpectations.count) skills practiced",
            in: app
        )
        dismissAchievementOverlays(in: app)

        let continueLesson = app.buttons["continue-next-lesson"].firstMatch
        XCTAssertTrue(continueLesson.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCompletionRestoresAfterRelaunch() throws {
        let lessons = try loadLessonExpectations()
        let firstLesson = try XCTUnwrap(lessons.first)
        let secondLesson = try XCTUnwrap(lessons.dropFirst().first)
        let app = launchApp(persistsData: true)

        let firstStart = app.buttons["start-lesson-\(firstLesson.id)"].firstMatch
        XCTAssertTrue(firstStart.waitForExistence(timeout: 15))
        activate(firstStart)

        let choice = app.buttons["choice-\(firstLesson.correctChoiceID)"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        select(
            choice,
            firstChoice: app.buttons[
                "choice-\(try XCTUnwrap(firstLesson.choices.first).id)"
            ],
            choiceIndex: firstLesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-answer"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .waitForExistence(timeout: 5)
        )

        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-ui-testing-data" }
        app.launch()
        prepareAfterLaunch(app)

        let restoredFirstLesson = app.buttons[
            "start-lesson-\(firstLesson.id)"
        ].firstMatch
        XCTAssertTrue(restoredFirstLesson.waitForExistence(timeout: 15))
        XCTAssertEqual(restoredFirstLesson.value as? String, "Completed")

        let restoredSecondLesson = app.buttons[
            "start-lesson-\(secondLesson.id)"
        ].firstMatch
        XCTAssertTrue(restoredSecondLesson.waitForExistence(timeout: 5))
        XCTAssertTrue(restoredSecondLesson.isEnabled)
    }

    @MainActor
    func testReviewQueueCompletesAndRestoresMistakeNotebook() throws {
        let firstLesson = try XCTUnwrap(loadLessonExpectations().first)
        let app = launchApp(persistsData: true, reviewFixture: true)

        let reviewSummary = app.descendants(matching: .any)[
            "journey-review-summary"
        ].firstMatch
        XCTAssertTrue(reviewSummary.waitForExistence(timeout: 15))
        assertValue(reviewSummary, equals: "1 review due", in: app)
        activate(reviewSummary)

        let reviewSkill = app.descendants(matching: .any)[
            "review-skill-\(firstLesson.id)"
        ].firstMatch
        XCTAssertTrue(reviewSkill.waitForExistence(timeout: 10))

        let correctChoice = app.buttons[
            "review-choice-\(firstLesson.correctChoiceID)"
        ].firstMatch
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons[
                "review-choice-\(try XCTUnwrap(firstLesson.choices.first).id)"
            ],
            choiceIndex: firstLesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-review-answer"].firstMatch
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-session-complete"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        let notebook = app.buttons["open-mistake-notebook"].firstMatch
        XCTAssertTrue(notebook.waitForExistence(timeout: 5))
        activate(notebook)
        XCTAssertTrue(
            app.descendants(matching: .any)["mistake-skill-\(firstLesson.id)"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-ui-testing-data" }
        app.launch()
        prepareAfterLaunch(app)

        let restoredSummary = app.descendants(matching: .any)[
            "journey-review-summary"
        ].firstMatch
        XCTAssertTrue(restoredSummary.waitForExistence(timeout: 15))
        assertValue(restoredSummary, equals: "No reviews due", in: app)
        activate(restoredSummary)

        let restoredNotebook = app.buttons["open-mistake-notebook"].firstMatch
        XCTAssertTrue(restoredNotebook.waitForExistence(timeout: 5))
        activate(restoredNotebook)
        XCTAssertTrue(
            app.descendants(matching: .any)["mistake-skill-\(firstLesson.id)"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testProfileBadgeUnlocksAfterCompletingFirstLesson() throws {
        let firstLesson = try XCTUnwrap(loadLessonExpectations().first)
        let app = launchApp()

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let progressSummary = app.staticTexts["profile-progress-summary"].firstMatch
        reveal(progressSummary, in: app)
        assertSummary(
            progressSummary,
            equals: "0 of \(try loadLessonExpectations().count) lessons completed",
            in: app
        )

        let firstLessonBadge = app.descendants(matching: .any)[
            "achievement-card-achievement.first-lesson"
        ].firstMatch
        reveal(firstLessonBadge, in: app)
        assertAchievement(
            firstLessonBadge,
            label: "First Lesson, Locked",
            value: "Locked, 0 of 1"
        )

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let startLesson = app.buttons["start-lesson-\(firstLesson.id)"].firstMatch
        reveal(startLesson, in: app)
        activate(startLesson)

        let choice = app.buttons["choice-\(firstLesson.correctChoiceID)"].firstMatch
        reveal(choice, in: app)
        select(
            choice,
            firstChoice: app.buttons["choice-\(try XCTUnwrap(firstLesson.choices.first).id)"],
            choiceIndex: firstLesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-answer"].firstMatch
        reveal(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .waitForExistence(timeout: 5)
        )
        let achievementOverlay = app.descendants(matching: .any)[
            "achievement-unlock-overlay"
        ].firstMatch
        XCTAssertTrue(achievementOverlay.waitForExistence(timeout: 5))
        XCTAssertEqual(achievementOverlay.value as? String, "achievement.first-lesson")
        dismissAchievementOverlays(in: app)

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let updatedProgressSummary = app.staticTexts["profile-progress-summary"].firstMatch
        reveal(updatedProgressSummary, in: app)
        assertSummary(
            updatedProgressSummary,
            equals: "1 of \(try loadLessonExpectations().count) lessons completed",
            in: app
        )
        let updatedFirstLessonBadge = app.descendants(matching: .any)[
            "achievement-card-achievement.first-lesson"
        ].firstMatch
        reveal(updatedFirstLessonBadge, in: app)
        assertAchievement(
            updatedFirstLessonBadge,
            label: "First Lesson, Earned",
            value: "Earned, 1 of 1"
        )
    }

    @MainActor
    func testProfileAvatarSavesLocally() {
        let app = launchApp()
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)

        let boyAvatar = app.descendants(matching: .any)[
            "profile-avatar-boy"
        ].firstMatch
        reveal(boyAvatar, in: app)

#if os(tvOS)
        let unknownAvatar = app.descendants(matching: .any)[
            "profile-avatar-unknown"
        ].firstMatch
        XCTAssertTrue(unknownAvatar.waitForExistence(timeout: 5))
        waitForFocus(on: unknownAvatar)
#else
        let customAvatar = app.descendants(matching: .any)[
            "profile-avatar-custom"
        ].firstMatch
        XCTAssertTrue(customAvatar.waitForExistence(timeout: 5))
        XCTAssertEqual(customAvatar.value as? String, "Not selected")
#endif

        focusAndActivate(boyAvatar, tvPath: [.right])
        XCTAssertEqual(boyAvatar.value as? String, "Selected")

        let saveProfile = app.buttons["save-profile"].firstMatch
        reveal(saveProfile, in: app)
        activate(saveProfile)
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-save-success"]
                .waitForExistence(timeout: 5)
        )

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let restoredBoyAvatar = app.descendants(matching: .any)[
            "profile-avatar-boy"
        ].firstMatch
        XCTAssertTrue(restoredBoyAvatar.waitForExistence(timeout: 5))
        XCTAssertEqual(restoredBoyAvatar.value as? String, "Selected")
    }

    @MainActor
    private func launchApp(
        skipIntro: Bool = true,
        persistsData: Bool = false,
        reviewFixture: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        if skipIntro {
            app.launchArguments.append("--skip-intro")
        }
        if persistsData {
            app.launchArguments.append("--ui-testing-persistent")
            app.launchArguments.append("--reset-ui-testing-data")
        }
        if reviewFixture {
            app.launchArguments.append("--ui-testing-review-fixture")
        }

#if os(macOS)
        app.launchArguments.append(contentsOf: ["-ApplePersistenceIgnoreState", "YES"])
#endif

        app.launch()
        prepareAfterLaunch(app)

        return app
    }

    @MainActor
    private func prepareAfterLaunch(_ app: XCUIApplication) {
#if os(macOS)
        app.activate()
        let window = app.windows.firstMatch
        if !window.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        XCTAssertTrue(window.waitForExistence(timeout: 5))
#endif
    }

    @MainActor
    private func openTab(
        _ identifier: String,
        label: String,
        in app: XCUIApplication,
        tvDirection: TabDirection
    ) {
#if os(macOS)
        app.activate()
        let labeledTab = app.buttons[label].firstMatch
        let tab = labeledTab.waitForExistence(timeout: 5)
            ? labeledTab
            : app.descendants(matching: .any)[identifier].firstMatch
#else
        let identifiedTab = app.descendants(matching: .any)[identifier].firstMatch
        let tab = identifiedTab.waitForExistence(timeout: 5)
            ? identifiedTab
            : app.buttons[label].firstMatch
#endif
        XCTAssertTrue(tab.waitForExistence(timeout: 5))

#if os(tvOS)
        let remote = XCUIRemote.shared
        let otherIdentifier = identifier == "profile-tab" ? "journey-tab" : "profile-tab"
        let otherTab = app.descendants(matching: .any)[otherIdentifier].firstMatch

        for _ in 0..<12 where !tab.hasFocus && !otherTab.hasFocus {
            remote.press(.up)
        }

        if !tab.hasFocus {
            remote.press(tvDirection == .left ? .left : .right)
        }
        waitForFocus(on: tab)
        remote.press(.select)
#else
        tab.tap()
#endif
    }

    @MainActor
    private func assertSummary(
        _ identifiedElement: XCUIElement,
        equals expectedText: String,
        in app: XCUIApplication
    ) {
        XCTAssertTrue(identifiedElement.waitForExistence(timeout: 5))

#if os(macOS)
        XCTAssertTrue(app.staticTexts[expectedText].firstMatch.waitForExistence(timeout: 5))
#else
        XCTAssertEqual(identifiedElement.label, expectedText)
#endif
    }

    @MainActor
    private func assertValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        in app: XCUIApplication
    ) {
#if os(macOS)
        if element.value as? String != expectedValue {
            XCTAssertTrue(
                app.staticTexts[expectedValue].firstMatch.waitForExistence(timeout: 5)
            )
        }
#else
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedValue),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
#endif
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        if element.waitForExistence(timeout: 2) {
            return
        }

#if os(tvOS)
        let remote = XCUIRemote.shared
        for _ in 0..<20 where !element.exists {
            remote.press(.down)
        }
#else
        for _ in 0..<12 where !element.exists {
            app.swipeUp()
        }
#endif

        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }

    @MainActor
    private func revealInteractive(_ element: XCUIElement, in app: XCUIApplication) {
#if os(tvOS)
        reveal(element, in: app)
#else
        _ = element.waitForExistence(timeout: 2)

        for _ in 0..<12 where !element.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
#endif
    }

    @MainActor
    private func assertAchievement(
        _ element: XCUIElement,
        label expectedLabel: String,
        value expectedValue: String
    ) {
        XCTAssertEqual(element.label, expectedLabel)

#if !os(macOS)
        XCTAssertEqual(element.value as? String, expectedValue)
#endif
    }

    @MainActor
    private func focusAndActivate(
        _ element: XCUIElement,
        tvPath: [FocusDirection] = []
    ) {
#if os(tvOS)
        let remote = XCUIRemote.shared
        for direction in tvPath where !element.hasFocus {
            press(direction, using: remote)
        }
        let directions: [XCUIRemote.Button] = [.down, .right, .down, .left]

        for index in 0..<48 where !element.hasFocus {
            remote.press(directions[index % directions.count])
        }

        XCTAssertTrue(element.hasFocus)
        remote.press(.select)
#else
        element.tap()
#endif
    }

#if os(tvOS)
    @MainActor
    private func waitForFocus(on element: XCUIElement) {
        let focused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasFocus == true"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [focused], timeout: 5), .completed)
    }
#endif

    @MainActor
    private func dismissAchievementOverlays(in app: XCUIApplication) {
        let dismiss = app.buttons["dismiss-achievement-unlock"].firstMatch

        for _ in 0..<6 {
            guard dismiss.waitForExistence(timeout: 0.5) else { return }
            activate(dismiss)
        }

        XCTAssertFalse(dismiss.exists)
    }

    private func loadLessonExpectations() throws -> [LessonExpectation] {
        let resourceURL = try XCTUnwrap(
            Bundle(for: Swift_LearnUITests.self).url(
                forResource: "swift-6.4-beta-foundations",
                withExtension: "json"
            )
        )
        let catalog = try JSONDecoder().decode(
            LearningCatalogExpectation.self,
            from: Data(contentsOf: resourceURL)
        )
        let lessons = catalog.levels.flatMap(\.lessons)
        XCTAssertEqual(lessons.count, 486)
        return lessons
    }

    @MainActor
    private func select(
        _ element: XCUIElement,
        firstChoice: XCUIElement,
        choiceIndex: Int
    ) {
#if os(tvOS)
        let remote = XCUIRemote.shared
        if !firstChoice.hasFocus && !element.hasFocus {
            remote.press(.down)
        }

        for _ in 0..<8 where !firstChoice.hasFocus {
            remote.press(.left)
        }
        for _ in 0..<choiceIndex where !element.hasFocus {
            remote.press(.right)
        }

        XCTAssertTrue(element.hasFocus)
        remote.press(.select)

        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Selected"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 2), .completed)
#else
        element.tap()
#endif
    }

    @MainActor
    private func activate(_ element: XCUIElement) {
#if os(tvOS)
        let remote = XCUIRemote.shared

        for _ in 0..<20 where !element.hasFocus {
            remote.press(.down)
        }

        remote.press(.select)
#else
        element.tap()
#endif
    }
}

private enum FocusDirection {
    case up
    case down
    case left
    case right
}

#if os(tvOS)
@MainActor
private func press(_ direction: FocusDirection, using remote: XCUIRemote) {
    switch direction {
    case .up:
        remote.press(.up)
    case .down:
        remote.press(.down)
    case .left:
        remote.press(.left)
    case .right:
        remote.press(.right)
    }
}
#endif

private enum TabDirection {
    case left
    case right
}

private struct LearningCatalogExpectation: Decodable {
    let levels: [Level]

    struct Level: Decodable {
        let lessons: [LessonExpectation]
    }
}

private struct LessonExpectation: Decodable {
    let id: String
    let title: String
    let correctChoiceID: String
    let choices: [Choice]

    var correctChoiceIndex: Int {
        choices.firstIndex { $0.id == correctChoiceID } ?? 0
    }

    struct Choice: Decodable {
        let id: String
    }
}
