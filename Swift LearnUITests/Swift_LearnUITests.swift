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
    func testCompletesEveryLessonAndUpdatesProgress() throws {
        let lessonExpectations = try loadLessonExpectations()
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

#if os(macOS)
        app.activate()
#endif

        let firstStart = app.buttons[
            "start-lesson-\(try XCTUnwrap(lessonExpectations.first).id)"
        ].firstMatch
        XCTAssertTrue(firstStart.waitForExistence(timeout: 15))

        for expectation in [lessonExpectations[1], try XCTUnwrap(lessonExpectations.last)] {
            let lockedLesson = app.buttons["start-lesson-\(expectation.id)"].firstMatch
            XCTAssertTrue(lockedLesson.waitForExistence(timeout: 5))
            XCTAssertFalse(lockedLesson.isEnabled)
        }

        activate(firstStart)

        XCTAssertTrue(app.staticTexts["lesson-instruction"].waitForExistence(timeout: 5))
        let lessonTitle = app.staticTexts["lesson-title"]

        for (index, expectation) in lessonExpectations.enumerated() {
            XCTAssertTrue(lessonTitle.waitForExistence(timeout: 5))
            XCTAssertEqual(lessonTitle.label, expectation.title)

            let choice = app.buttons["choice-\(expectation.correctChoiceID)"].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            select(
                choice,
                firstChoice: app.buttons["choice-\(try XCTUnwrap(expectation.choices.first).id)"],
                choiceIndex: expectation.correctChoiceIndex
            )

            let submit = app.buttons["submit-answer"].firstMatch
            XCTAssertTrue(submit.waitForExistence(timeout: 5))
            activate(submit)

            XCTAssertTrue(
                app.descendants(matching: .any)["lesson-complete-feedback"]
                    .waitForExistence(timeout: 5)
            )
            XCTAssertEqual(
                app.staticTexts["lesson-progress-summary"].label,
                "\(index + 1) of \(lessonExpectations.count) skills practiced"
            )
            dismissAchievementOverlays(in: app)

            if index < lessonExpectations.count - 1 {
                let continueLesson = app.buttons["continue-next-lesson"].firstMatch
                XCTAssertTrue(continueLesson.waitForExistence(timeout: 5))
                activate(continueLesson)
            }
        }
    }

    @MainActor
    func testProfileBadgeUnlocksAfterCompletingFirstLesson() throws {
        let firstLesson = try XCTUnwrap(loadLessonExpectations().first)
        let app = launchApp()

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let progressSummary = app.staticTexts["profile-progress-summary"]
        reveal(progressSummary, in: app)
        XCTAssertEqual(
            progressSummary.label,
            "0 of \(try loadLessonExpectations().count) lessons completed"
        )

        let firstLessonBadge = app.descendants(matching: .any)[
            "achievement-card-achievement.first-lesson"
        ].firstMatch
        reveal(firstLessonBadge, in: app)
        XCTAssertTrue((firstLessonBadge.value as? String)?.hasPrefix("Locked") == true)

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
        reveal(progressSummary, in: app)
        XCTAssertEqual(
            progressSummary.label,
            "1 of \(try loadLessonExpectations().count) lessons completed"
        )
        reveal(firstLessonBadge, in: app)
        XCTAssertTrue((firstLessonBadge.value as? String)?.hasPrefix("Earned") == true)
    }

    @MainActor
    func testProfilePreferencesSaveLocally() {
        let app = launchApp()
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)

        let terminalAvatar = app.descendants(matching: .any)[
            "profile-avatar-terminal"
        ].firstMatch
        reveal(terminalAvatar, in: app)
        focusAndActivate(terminalAvatar, tvPath: [.right])
        XCTAssertEqual(terminalAvatar.value as? String, "Selected")

        let darkAppearance = app.descendants(matching: .any)[
            "profile-appearance-dark"
        ].firstMatch
        reveal(darkAppearance, in: app)
        focusAndActivate(darkAppearance, tvPath: [.down, .right])
        XCTAssertEqual(darkAppearance.value as? String, "Selected")

        let reducedMotion = app.descendants(matching: .any)[
            "profile-motion-reduced"
        ].firstMatch
        reveal(reducedMotion, in: app)
        focusAndActivate(reducedMotion, tvPath: [.down])
        XCTAssertEqual(reducedMotion.value as? String, "Selected")

        let saveProfile = app.buttons["save-profile"].firstMatch
        reveal(saveProfile, in: app)
        focusAndActivate(saveProfile, tvPath: [.down])
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-save-success"]
                .waitForExistence(timeout: 5)
        )

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        XCTAssertEqual(terminalAvatar.value as? String, "Selected")
        XCTAssertEqual(darkAppearance.value as? String, "Selected")
        XCTAssertEqual(reducedMotion.value as? String, "Selected")
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

#if os(macOS)
        app.activate()
#endif

        return app
    }

    @MainActor
    private func openTab(
        _ identifier: String,
        label: String,
        in app: XCUIApplication,
        tvDirection: TabDirection
    ) {
        let identifiedTab = app.descendants(matching: .any)[identifier].firstMatch
        let tab = identifiedTab.waitForExistence(timeout: 5)
            ? identifiedTab
            : app.buttons[label].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5))

#if os(tvOS)
        let remote = XCUIRemote.shared
        for _ in 0..<12 where !tab.hasFocus {
            remote.press(.up)
        }
        for _ in 0..<12 where !tab.hasFocus {
            remote.press(tvDirection == .left ? .left : .right)
        }
        XCTAssertTrue(tab.hasFocus)
        remote.press(.select)
#else
        tab.tap()
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
        XCTAssertFalse(lessons.isEmpty)
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
