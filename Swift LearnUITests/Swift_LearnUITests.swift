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
#if os(iOS)
        addUIInterruptionMonitor(withDescription: "Dismiss Apple account prompts") { alert in
            MainActor.assumeIsolated {
                let notNow = alert.buttons["Not Now"].firstMatch
                guard notNow.exists else { return false }
                notNow.tap()
                return true
            }
        }
#endif
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

        let next = app.buttons["intro-next-1"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        activateIntroPrimary(next, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["intro-step-2"].firstMatch
                .waitForExistence(timeout: 5)
        )

        let secondNext = app.buttons["intro-next-2"].firstMatch
        XCTAssertTrue(secondNext.waitForExistence(timeout: 5))
        activateIntroPrimary(secondNext, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["intro-step-3"].firstMatch
                .waitForExistence(timeout: 5)
        )

        let thirdNext = app.buttons["intro-next-3"].firstMatch
        XCTAssertTrue(thirdNext.waitForExistence(timeout: 5))
        activateIntroPrimary(thirdNext, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["intro-step-4"].firstMatch
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts[
                "The Swift Programming Language — Swift 6.4 beta"
            ].firstMatch.waitForExistence(timeout: 5)
        )
        let sourceDetailText =
            "Learning activities are adapted from this catalog edition. "
                + "Source ID: swift-6.4-beta-2026-07-31. "
                + "Supplemental topics are identified separately."
#if os(macOS)
        let sourceDetailPredicate = NSPredicate(
            format: "value == %@",
            sourceDetailText
        )
#else
        let sourceDetailPredicate = NSPredicate(
            format: "label == %@",
            sourceDetailText
        )
#endif
        let sourceDetail = app.staticTexts.matching(sourceDetailPredicate).firstMatch
        XCTAssertTrue(sourceDetail.waitForExistence(timeout: 5))

        let startLearning = app.buttons["intro-start-learning"].firstMatch
        XCTAssertTrue(startLearning.waitForExistence(timeout: 5))
        activateIntroPrimary(startLearning, in: app)

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
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

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
    func testFirstLevelCompletesWithOneCelebration() throws {
        let level = try XCTUnwrap(loadCatalogExpectation().levels.first)
        let finalLesson = try XCTUnwrap(level.lessons.last)
        let firstChoice = try XCTUnwrap(finalLesson.choices.first)
        let app = launchApp(levelCompletionFixture: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let resume = app.buttons["resume-current-task"].firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        activate(resume)

        let correctChoice = app.buttons[
            "choice-\(finalLesson.correctChoiceID)"
        ].firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
        select(
            correctChoice,
            firstChoice: app.buttons["choice-\(firstChoice.id)"].firstMatch,
            choiceIndex: finalLesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-answer"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        activate(submit)

        let overlay = app.descendants(matching: .any)[
            "achievement-unlock-overlay"
        ].firstMatch
        XCTAssertTrue(overlay.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Level Complete"].firstMatch.exists)

        let dismiss = app.buttons["dismiss-achievement-unlock"].firstMatch
        XCTAssertTrue(dismiss.waitForExistence(timeout: 5))
        activate(dismiss)
        let dismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: overlay
        )
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        assertSummary(
            app.staticTexts["lesson-progress-summary"].firstMatch,
            equals: "\(level.lessons.count) of \(try loadLessonExpectations().count) skills practiced",
            in: app
        )
    }

    @MainActor
    func testOutputPredictionActivityCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first {
                $0.activityType == "outputPrediction"
            }
        )
        let firstChoice = try XCTUnwrap(lesson.choices.first)
        let app = launchApp(activityFixture: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        reveal(startLesson, in: app)
        activate(startLesson)

        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-outputPrediction"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        let prompt = app.staticTexts["activity-prompt"].firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
#if os(macOS)
        XCTAssertEqual(prompt.value as? String, "What does this code print?")
#else
        XCTAssertEqual(prompt.label, "What does this code print?")
#endif

        let correctChoice = app.buttons[
            "choice-\(lesson.correctChoiceID)"
        ].firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
        select(
            correctChoice,
            firstChoice: app.buttons["choice-\(firstChoice.id)"],
            choiceIndex: lesson.correctChoiceIndex
        )

        let submit = app.buttons["submit-answer"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testCodeOrderingActivityCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "codeOrdering" }
        )
        XCTAssertEqual(lesson.id, "swift.comments.multiline")
        XCTAssertEqual(lesson.correctOrderIDs.count, 5)
        let app = launchApp(codeOrderingFixture: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        openJourneyLesson(startLesson, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-codeOrdering"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        let submit = app.buttons["submit-answer"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertFalse(submit.isEnabled)
        let firstFragment = app.buttons["activity-fragment-\(lesson.correctOrderIDs[0])"].firstMatch
        revealInteractive(firstFragment, in: app)
        selectOrderingFragment(firstFragment)
        let reset = app.buttons["activity-reset-composition"].firstMatch
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        revealInteractive(reset, in: app)
        activate(reset)
        XCTAssertFalse(submit.isEnabled)
        for id in lesson.correctOrderIDs {
            let fragment = app.buttons["activity-fragment-\(id)"].firstMatch
            revealInteractive(fragment, in: app)
            selectOrderingFragment(fragment)
            XCTAssertTrue(
                app.buttons["activity-ordered-\(id)"].firstMatch
                    .waitForExistence(timeout: 5)
            )
        }
        XCTAssertTrue(submit.isEnabled)
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testCodeOrderingReviewCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "codeOrdering" }
        )
        let app = launchApp(
            persistsData: true,
            reviewFixture: true,
            codeOrderingFixture: true
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let summary = app.descendants(matching: .any)["journey-review-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        activate(summary)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-skill-\(lesson.id)"]
                .firstMatch.waitForExistence(timeout: 10)
        )

        for id in lesson.correctOrderIDs {
            let fragment = app.buttons["activity-fragment-\(id)"].firstMatch
            revealInteractive(fragment, in: app)
            selectOrderingFragment(fragment)
        }
        let submit = app.buttons["submit-review-answer"].firstMatch
        XCTAssertTrue(submit.isEnabled)
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-session-complete"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testDiagnosticSelectionActivityCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "diagnosticSelection" }
        )
        let firstChoice = try XCTUnwrap(lesson.choices.first)
        let app = launchApp(activityKind: "diagnosticSelection")
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        openJourneyLesson(startLesson, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-diagnosticSelection"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        let correctChoice = app.buttons["choice-\(lesson.correctChoiceID)"].firstMatch
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons["choice-\(firstChoice.id)"],
            choiceIndex: lesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-answer"].firstMatch
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testLessonAnswersAreNotShownInTheAuthoredOrder() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "diagnosticSelection" }
        )
        let authored = lesson.choices.map(\.id)
        try XCTSkipUnless(
            authored.count >= 3,
            "A shuffle is only observable with three or more answers"
        )

        // Pinned: the fixture must reproduce the authored order exactly, which
        // is what keeps the rest of this suite deterministic.
        let pinned = launchApp(activityKind: "diagnosticSelection")
        openTab("journey-tab", label: "Journey", in: pinned, tvDirection: .left)
        openJourneyLesson(
            pinned.buttons["start-lesson-\(lesson.id)"].firstMatch,
            in: pinned
        )
        XCTAssertTrue(
            pinned.descendants(matching: .any)["activity-kind-diagnosticSelection"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        XCTAssertEqual(
            displayedChoiceIDs(prefix: "choice-", ids: authored, in: pinned),
            authored
        )
        pinned.terminate()

        // Shuffled: the same question, every answer still present, but not in
        // the order the catalog authored them in.
        let app = launchApp(
            activityKind: "diagnosticSelection",
            fixedChoiceOrder: false
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        openJourneyLesson(
            app.buttons["start-lesson-\(lesson.id)"].firstMatch,
            in: app
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-diagnosticSelection"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        let shuffled = displayedChoiceIDs(prefix: "choice-", ids: authored, in: app)
        XCTAssertEqual(
            shuffled.sorted(),
            authored.sorted(),
            "Every authored answer must still be shown exactly once"
        )
        XCTAssertNotEqual(shuffled, authored)
    }

    @MainActor
    func testLessonAnswerOrderIsStableWithinAnAttemptAndAnsweredByIdentifier() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "diagnosticSelection" }
        )
        let authored = lesson.choices.map(\.id)
        try XCTSkipUnless(
            authored.count >= 3,
            "A shuffle is only observable with three or more answers"
        )
        let app = launchApp(
            activityKind: "diagnosticSelection",
            fixedChoiceOrder: false
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        openJourneyLesson(startLesson, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-diagnosticSelection"]
                .firstMatch.waitForExistence(timeout: 10)
        )

        let firstReading = displayedChoiceIDs(prefix: "choice-", ids: authored, in: app)
        let wrongChoiceID = try XCTUnwrap(
            authored.first { $0 != lesson.correctChoiceID }
        )
        let wrongChoice = app.buttons["choice-\(wrongChoiceID)"].firstMatch
        revealInteractive(wrongChoice, in: app)
        selectByFocus(wrongChoice, in: app)
        let submit = app.buttons["submit-answer"].firstMatch
        revealInteractive(submit, in: app)
        activateByFocus(submit, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-retry-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        // A wrong answer must not move the answers under the learner.
        XCTAssertEqual(
            displayedChoiceIDs(prefix: "choice-", ids: authored, in: app),
            firstReading
        )

        let correctChoice = app.buttons["choice-\(lesson.correctChoiceID)"].firstMatch
        revealInteractive(correctChoice, in: app)
        selectByFocus(correctChoice, in: app)
        revealInteractive(submit, in: app)
        activateByFocus(submit, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 10)
        )
    }

    @MainActor
    func testDiagnosticSelectionReviewCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "diagnosticSelection" }
        )
        let firstChoice = try XCTUnwrap(lesson.choices.first)
        let app = launchApp(
            persistsData: true,
            reviewFixture: true,
            activityKind: "diagnosticSelection"
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let summary = app.descendants(matching: .any)["journey-review-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        activate(summary)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-skill-\(lesson.id)"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        let correctChoice = app.buttons[
            "review-choice-\(lesson.correctChoiceID)"
        ].firstMatch
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons["review-choice-\(firstChoice.id)"],
            choiceIndex: lesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-review-answer"].firstMatch
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-session-complete"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testCodeRepairActivityCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "codeRepair" }
        )
        let firstChoice = try XCTUnwrap(lesson.choices.first)
        let app = launchApp(activityKind: "codeRepair")
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        openJourneyLesson(startLesson, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-codeRepair"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        let code = app.staticTexts["lesson-code"].firstMatch
        XCTAssertTrue(code.waitForExistence(timeout: 5))
        let correctChoice = app.buttons["choice-\(lesson.correctChoiceID)"].firstMatch
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons["choice-\(firstChoice.id)"],
            choiceIndex: lesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-answer"].firstMatch
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testCodeRepairReviewCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "codeRepair" }
        )
        let firstChoice = try XCTUnwrap(lesson.choices.first)
        let app = launchApp(
            persistsData: true,
            reviewFixture: true,
            activityKind: "codeRepair"
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let summary = app.descendants(matching: .any)["journey-review-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        activate(summary)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-skill-\(lesson.id)"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        let correctChoice = app.buttons[
            "review-choice-\(lesson.correctChoiceID)"
        ].firstMatch
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons["review-choice-\(firstChoice.id)"],
            choiceIndex: lesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-review-answer"].firstMatch
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-session-complete"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testConstrainedEditingActivityCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "constrainedEditing" }
        )
        let app = launchApp(activityKind: "constrainedEditing")
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        openJourneyLesson(startLesson, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-constrainedEditing"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        enterConstrainedExpression(lesson: lesson, in: app)
        let submit = app.buttons["submit-answer"].firstMatch
        XCTAssertTrue(submit.isEnabled)
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testConstrainedEditingReviewCompletes() throws {
        let lesson = try XCTUnwrap(
            loadLessonExpectations().first { $0.activityType == "constrainedEditing" }
        )
        let app = launchApp(
            persistsData: true,
            reviewFixture: true,
            activityKind: "constrainedEditing"
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let summary = app.descendants(matching: .any)["journey-review-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        activate(summary)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-skill-\(lesson.id)"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        enterConstrainedExpression(lesson: lesson, in: app)
        let submit = app.buttons["submit-review-answer"].firstMatch
        XCTAssertTrue(submit.isEnabled)
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["review-session-complete"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testLevelBossChallengeCombinesTwoSkills() throws {
        let level = try XCTUnwrap(loadCatalogExpectation().levels.first)
        let items = Array(level.lessons.prefix(2))
        XCTAssertEqual(items.count, 2)
        let app = launchApp(
            bossFixture: true,
            failsFirstBossCompletionSave: true
        )
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let startBoss = app.buttons[
            "start-boss-challenge-\(level.id)"
        ].firstMatch
        revealInteractive(startBoss, in: app)
        XCTAssertEqual(startBoss.value as? String, "Available")
        activate(startBoss)

        XCTAssertTrue(
            app.descendants(matching: .any)["boss-challenge-title"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        for item in items {
            let itemTitle = app.descendants(matching: .any)[
                "boss-item-\(item.id)"
            ].firstMatch
            XCTAssertTrue(itemTitle.waitForExistence(timeout: 5))

            let correctChoice = app.buttons[
                "boss-choice-\(item.id)-\(item.correctChoiceID)"
            ].firstMatch
            let firstChoice = try XCTUnwrap(item.choices.first)
            XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
#if os(tvOS)
            assertInitialChoiceFocus(
                app.buttons["boss-choice-\(item.id)-\(firstChoice.id)"].firstMatch
            )
#endif
            select(
                correctChoice,
                firstChoice: app.buttons[
                    "boss-choice-\(item.id)-\(firstChoice.id)"
                ],
                choiceIndex: item.correctChoiceIndex
            )

            let submit = app.buttons["submit-boss-answer"].firstMatch
            revealInteractive(submit, in: app)
            activate(submit)
        }

        XCTAssertTrue(
            app.descendants(matching: .any)["boss-challenge-passed"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        assertSummary(
            app.staticTexts["boss-challenge-result-summary"].firstMatch,
            equals: "2 of 2 skills verified",
            in: app
        )

        let completionError = app.descendants(matching: .any)[
            "boss-completion-save-error"
        ].firstMatch
        XCTAssertTrue(completionError.waitForExistence(timeout: 5))
        let retryCompletion = app.buttons[
            "retry-boss-completion-save"
        ].firstMatch
        revealInteractive(retryCompletion, in: app)
        activate(retryCompletion)
        XCTAssertFalse(completionError.waitForExistence(timeout: 1))

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let bossAchievement = app.descendants(matching: .any)[
            "achievement-card-achievement.boss.\(level.id)"
        ].firstMatch
        reveal(bossAchievement, in: app, maxMoves: 60)
        assertAchievement(
            bossAchievement,
            label: "\(level.title) Boss Challenge, Earned",
            value: "Earned, 1 of 1"
        )
    }

    @MainActor
    func testGuidedProjectValidatesThreeSkills() throws {
        let requirements = Array(try loadLessonExpectations().prefix(3))
        XCTAssertEqual(requirements.count, 3)
        let app = launchApp(projectFixture: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let startProject = app.buttons[
            "start-learning-project-swift-foundations"
        ].firstMatch
        revealInteractive(startProject, in: app)
        XCTAssertEqual(startProject.value as? String, "Available")
        activate(startProject)

        XCTAssertTrue(
            app.descendants(matching: .any)["learning-project-title"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["activity-kind-projectValidation"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.descendants(matching: .any)[
                "project-validation-item-requirement.\(requirements[0].id)"
            ].firstMatch.value as? String,
            "Pending"
        )

        for (index, lesson) in requirements.enumerated() {
            let requirementID = "requirement.\(lesson.id)"
            XCTAssertTrue(
                app.descendants(matching: .any)[
                    "project-requirement-\(requirementID)"
                ].firstMatch.waitForExistence(timeout: 5)
            )

            let correctChoice = app.buttons[
                "project-choice-\(requirementID)-\(lesson.correctChoiceID)"
            ].firstMatch
            let firstChoice = try XCTUnwrap(lesson.choices.first)
            XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
#if os(tvOS)
            assertInitialChoiceFocus(
                app.buttons["project-choice-\(requirementID)-\(firstChoice.id)"].firstMatch
            )
#else
            revealInteractive(correctChoice, in: app)
#endif
            select(
                correctChoice,
                firstChoice: app.buttons[
                    "project-choice-\(requirementID)-\(firstChoice.id)"
                ],
                choiceIndex: lesson.correctChoiceIndex
            )

            let actionID = index == requirements.count - 1
                ? "submit-project"
                : "save-project-requirement"
            let action = app.buttons[actionID].firstMatch
            revealInteractive(action, in: app)
            activate(action)
        }

        XCTAssertTrue(
            app.descendants(matching: .any)["learning-project-passed"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["project-validation-result"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.descendants(matching: .any)[
                "project-validation-item-requirement.\(requirements[0].id)"
            ].firstMatch.value as? String,
            "Passed"
        )
        assertSummary(
            app.staticTexts["learning-project-result-summary"].firstMatch,
            equals: "3 of 3 requirements validated",
            in: app
        )

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let projectAchievement = app.descendants(matching: .any)[
            "achievement-card-achievement.project.swift-foundations"
        ].firstMatch
        reveal(projectAchievement, in: app, maxMoves: 60)
        assertAchievement(
            projectAchievement,
            label: "Build a Practice Setup, Earned",
            value: "Earned, 1 of 1"
        )
    }

    @MainActor
    func testGuidedProjectValidationShowsNeedsReviewForFailedRequirement() throws {
        let requirements = Array(try loadLessonExpectations().prefix(3))
        XCTAssertEqual(requirements.count, 3)
        let app = launchApp(projectFixture: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let start = app.buttons["start-learning-project-swift-foundations"].firstMatch
        revealInteractive(start, in: app)
        activate(start)
        XCTAssertTrue(app.descendants(matching: .any)["activity-kind-projectValidation"]
            .firstMatch.waitForExistence(timeout: 5))

        for (index, lesson) in requirements.enumerated() {
            let requirementID = "requirement.\(lesson.id)"
            let first = try XCTUnwrap(lesson.choices.first)
            let selected = index == requirements.count - 1
                ? try XCTUnwrap(lesson.choices.first { $0.id != lesson.correctChoiceID })
                : try XCTUnwrap(lesson.choices.first { $0.id == lesson.correctChoiceID })
            let choice = app.buttons[
                "project-choice-\(requirementID)-\(selected.id)"
            ].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
#if os(tvOS)
            assertInitialChoiceFocus(
                app.buttons["project-choice-\(requirementID)-\(first.id)"].firstMatch
            )
#else
            revealInteractive(choice, in: app)
#endif
            select(
                choice,
                firstChoice: app.buttons[
                    "project-choice-\(requirementID)-\(first.id)"
                ],
                choiceIndex: try XCTUnwrap(lesson.choices.firstIndex { $0.id == selected.id })
            )
            let action = app.buttons[
                index == requirements.count - 1
                    ? "submit-project" : "save-project-requirement"
            ].firstMatch
            revealInteractive(action, in: app)
            activate(action)
        }

        XCTAssertTrue(app.descendants(matching: .any)["learning-project-needs-review"]
            .firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["project-validation-result"]
            .firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(
            app.descendants(matching: .any)[
                "project-validation-item-requirement.\(requirements[2].id)"
            ].firstMatch.value as? String,
            "Needs review"
        )
    }

    @MainActor
    func testCompletionRestoresAfterRelaunch() throws {
        let lessons = try loadLessonExpectations()
        let firstLesson = try XCTUnwrap(lessons.first)
        let secondLesson = try XCTUnwrap(lessons.dropFirst().first)
        let app = launchApp(persistsData: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

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
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

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
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

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
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

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
        let app = launchApp(persistsData: true)

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let progressSummary = app.staticTexts["profile-progress-summary"].firstMatch
        reveal(progressSummary, in: app)
        assertSummary(
            progressSummary,
            equals: "0 of \(try loadLessonExpectations().count) lessons completed",
            in: app
        )
        let dailyGoal = app.staticTexts["profile-daily-goal"].firstMatch
        reveal(dailyGoal, in: app)
        assertSummary(dailyGoal, equals: "Today: 0 of 20 XP", in: app)

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
#if os(macOS)
        XCTAssertTrue(
            app.staticTexts["First Lesson"].firstMatch
                .waitForExistence(timeout: 5)
        )
#else
        XCTAssertEqual(achievementOverlay.value as? String, "achievement.first-lesson")
#endif
        dismissAchievementOverlays(in: app)

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let updatedProgressSummary = app.staticTexts["profile-progress-summary"].firstMatch
        reveal(updatedProgressSummary, in: app)
        assertSummary(
            updatedProgressSummary,
            equals: "1 of \(try loadLessonExpectations().count) lessons completed",
            in: app
        )
        let completedDailyGoal = app.staticTexts["profile-daily-goal"].firstMatch
        reveal(completedDailyGoal, in: app)
        assertSummary(completedDailyGoal, equals: "Today: 20 of 20 XP", in: app)
        let momentum = app.staticTexts["profile-momentum-summary"].firstMatch
        reveal(momentum, in: app)
        assertSummary(momentum, equals: "20 total XP, 1 streak day, 0 recovery tokens", in: app)
        let updatedFirstLessonBadge = app.descendants(matching: .any)[
            "achievement-card-achievement.first-lesson"
        ].firstMatch
        reveal(updatedFirstLessonBadge, in: app)
        assertAchievement(
            updatedFirstLessonBadge,
            label: "First Lesson, Earned",
            value: "Earned, 1 of 1"
        )

        let showcaseButton = app.buttons[
            "showcase-achievement-achievement.first-lesson"
        ].firstMatch
        revealInteractive(showcaseButton, in: app)
        activate(showcaseButton)
#if os(macOS)
        XCTAssertEqual(showcaseButton.label, "Remove from Showcase")
#else
        XCTAssertEqual(showcaseButton.value as? String, "Selected")
#endif

        let showcasedBadge = app.descendants(matching: .any)[
            "profile-badge-showcase-achievement.first-lesson"
        ].firstMatch
        reveal(showcasedBadge, in: app)
        XCTAssertEqual(showcasedBadge.label, "First Lesson, Showcased")

        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-ui-testing-data" }
        app.launch()
        prepareAfterLaunch(app)
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let restoredShowcase = app.descendants(matching: .any)[
            "profile-badge-showcase-achievement.first-lesson"
        ].firstMatch
        reveal(restoredShowcase, in: app)
        XCTAssertEqual(restoredShowcase.label, "First Lesson, Showcased")

        let recentActivity = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND identifier != %@",
                "profile-recent-activity-",
                "profile-recent-activity-section"
            )
        ).firstMatch
        reveal(recentActivity, in: app)
        XCTAssertEqual(recentActivity.label, firstLesson.title)
#if !os(macOS)
        XCTAssertEqual(recentActivity.value as? String, "Lesson, Correct")
#endif
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
#if os(macOS)
        XCTAssertEqual(customAvatar.label, "Choose Memoji or photo")
#else
        XCTAssertEqual(customAvatar.value as? String, "Not selected")
#endif
#endif

        focusAndActivate(boyAvatar, tvPath: [.right])
        XCTAssertEqual(boyAvatar.value as? String, "Selected")

        let saveProfile = app.buttons["save-profile"].firstMatch
        revealInteractive(saveProfile, in: app)
        activate(saveProfile)
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-save-success"]
                .waitForExistence(timeout: 5)
        )

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
#if os(macOS)
        XCTAssertTrue(
            app.scrollViews["profile-screen"].firstMatch.waitForExistence(timeout: 5)
        )
        scrollToTop(in: app)
#endif
        let restoredBoyAvatar = app.descendants(matching: .any)[
            "profile-avatar-boy"
        ].firstMatch
        revealInteractive(restoredBoyAvatar, in: app)
        XCTAssertEqual(restoredBoyAvatar.value as? String, "Selected")
    }

    @MainActor
    func testProfileResetStartsLearningFromBeginning() throws {
        let lessons = try loadLessonExpectations()
        let firstLesson = try XCTUnwrap(lessons.first)
        let secondLesson = try XCTUnwrap(lessons.dropFirst().first)
        let firstChoice = try XCTUnwrap(firstLesson.choices.first)
        let app = launchApp()
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let firstStart = app.buttons["start-lesson-\(firstLesson.id)"].firstMatch
        revealInteractive(firstStart, in: app)
        activate(firstStart)

        let correctChoice = app.buttons[
            "choice-\(firstLesson.correctChoiceID)"
        ].firstMatch
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons["choice-\(firstChoice.id)"],
            choiceIndex: firstLesson.correctChoiceIndex
        )
        let submit = app.buttons["submit-answer"].firstMatch
        revealInteractive(submit, in: app)
        activate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        dismissAchievementOverlays(in: app)

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let completedSummary = app.staticTexts["profile-progress-summary"].firstMatch
        reveal(completedSummary, in: app)
        assertSummary(
            completedSummary,
            equals: "1 of \(lessons.count) lessons completed",
            in: app
        )

        let showcaseButton = app.buttons[
            "showcase-achievement-achievement.first-lesson"
        ].firstMatch
        revealInteractive(showcaseButton, in: app)
        activate(showcaseButton)
        XCTAssertTrue(
            app.descendants(matching: .any)[
                "profile-badge-showcase-achievement.first-lesson"
            ].firstMatch.waitForExistence(timeout: 5)
        )

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)

        let reset = app.buttons["reset-learning-progress"].firstMatch
#if !os(tvOS)
        scrollToTop(in: app)
#endif
        revealInteractive(reset, in: app)
        focusAndActivate(
            reset,
            tvPath: Array(repeating: .up, count: 96)
        )

        let confirm = app.buttons["confirm-reset-learning-progress"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        activateResetConfirmation(confirm)
        XCTAssertTrue(
            app.descendants(matching: .any)["learning-progress-reset-success"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        let resetSummary = app.staticTexts["profile-progress-summary"].firstMatch
        assertSummary(
            resetSummary,
            equals: "0 of \(lessons.count) lessons completed",
            in: app
        )
        let recentActivitySection = app.descendants(matching: .any)[
            "profile-recent-activity-section"
        ].firstMatch
        XCTAssertTrue(recentActivitySection.waitForExistence(timeout: 5))
        assertValue(
            recentActivitySection,
            equals: "No Learning Activity Yet",
            in: app
        )
        let emptyShowcase = app.descendants(matching: .any)[
            "profile-badge-showcase-empty"
        ].firstMatch
        reveal(emptyShowcase, in: app)
        XCTAssertTrue(emptyShowcase.exists)

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let resetFirstLesson = app.buttons[
            "start-lesson-\(firstLesson.id)"
        ].firstMatch
        XCTAssertTrue(resetFirstLesson.waitForExistence(timeout: 15))
        XCTAssertEqual(resetFirstLesson.value as? String, "Available")

        let resetSecondLesson = app.buttons[
            "start-lesson-\(secondLesson.id)"
        ].firstMatch
        XCTAssertTrue(resetSecondLesson.waitForExistence(timeout: 5))
        XCTAssertFalse(resetSecondLesson.isEnabled)
        XCTAssertEqual(resetSecondLesson.value as? String, "Locked")
    }

    @MainActor
    func testResumeAndLockedReasonUseTheCurrentJourney() throws {
        let catalog = try loadCatalogExpectation()
        let level = try XCTUnwrap(catalog.levels.first)
        let firstLesson = try XCTUnwrap(level.lessons.first)
        let secondLesson = try XCTUnwrap(level.lessons.dropFirst().first)
        let app = launchApp()
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let resume = app.buttons["resume-current-task"].firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        assertValue(resume, equals: firstLesson.title, in: app)

        let openLevel = app.buttons["open-level-\(level.id)"].firstMatch
        XCTAssertTrue(openLevel.waitForExistence(timeout: 20))
        focusAndActivate(openLevel)

        let lockedLesson = app.buttons["level-lesson-\(secondLesson.id)"].firstMatch
        XCTAssertTrue(lockedLesson.waitForExistence(timeout: 5))
#if os(tvOS)
        let lockedLessonCell = focusableListCell(
            containing: lockedLesson,
            in: app
        )
        focusAndActivate(
            lockedLessonCell,
            tvPath: Array(repeating: .down, count: 48)
        )
#else
        focusAndActivate(lockedLesson)
#endif
        XCTAssertTrue(
            app.descendants(matching: .any)["locked-reason-\(secondLesson.id)"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testDiscoverySearchFindsCanonicalSkill() throws {
        let firstLesson = try XCTUnwrap(loadLessonExpectations().first)
        let app = launchApp(discoveryQuery: firstLesson.title, rightToLeft: true)
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let openDiscovery = app.buttons["open-learning-discovery"].firstMatch
        XCTAssertTrue(openDiscovery.waitForExistence(timeout: 15))
        focusAndActivate(openDiscovery)

        let result = app.buttons["discovery-skill-\(firstLesson.id)"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        assertValue(result, equals: "Available", in: app)
#if os(tvOS)
        let resultCell = focusableListCell(containing: result, in: app)
        focusAndActivate(
            resultCell,
            tvPath: Array(repeating: .down, count: 48)
        )
#else
        focusAndActivate(result)
#endif
        XCTAssertTrue(
            app.descendants(matching: .any)["discovery-skill-detail"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testSupplementalTrackIsSeparatedFromBookCoverage() {
        let app = launchApp()
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)

        let openDiscovery = app.buttons["open-learning-discovery"].firstMatch
        XCTAssertTrue(openDiscovery.waitForExistence(timeout: 15))
        focusAndActivate(openDiscovery)

        let track = app.buttons[
            "supplemental-track-supplemental.architecture.swift-learn"
        ].firstMatch
        XCTAssertTrue(track.waitForExistence(timeout: 10))
#if os(tvOS)
        let remote = XCUIRemote.shared
        remote.press(.down)
        remote.press(.down)
        let trackCell = focusableListCell(containing: track, in: app)
        waitForFocus(on: trackCell)
        remote.press(.select)
#else
        focusAndActivate(
            track,
            tvPath: [.down, .down]
        )
#endif
        XCTAssertTrue(
            app.descendants(matching: .any)["supplemental-scope-label"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)[
                "supplemental-lesson-supplemental.architecture.dependency-direction"
            ].firstMatch.waitForExistence(timeout: 5)
        )

        let lesson = app.buttons[
            "supplemental-lesson-supplemental.architecture.dependency-direction"
        ].firstMatch
#if os(tvOS)
        let lessonCell = focusableListCell(containing: lesson, in: app)
        waitForFocus(on: lessonCell)
        XCUIRemote.shared.press(.select)
#else
        focusAndActivate(
            lesson,
            tvPath: Array(repeating: .up, count: 48)
        )
#endif

        let correctChoice = app.buttons["supplemental-choice-correct"].firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
        focusAndActivate(correctChoice)

        let submit = app.buttons["submit-supplemental-practice"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
#if os(macOS)
        app.activate()
#endif
        focusAndActivate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["supplemental-practice-result"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testSupplementalUnitTestAuthoringLab() {
        let app = launchApp()
        openSupplementalLesson(
            trackID: "supplemental.testing.automation",
            lessonID: "supplemental.testing.swift-testing",
            in: app
        )
        let requiredAssertion = app.descendants(matching: .any)[
            "activity-required-assertion"
        ].firstMatch
        XCTAssertTrue(requiredAssertion.waitForExistence(timeout: 5))
        XCTAssertTrue(accessibleText(of: requiredAssertion).contains("#expect"))
        composeSupplementalAssertion(
            "#expect(result.isCorrect == true)",
            tokenIDs: ["expect", "result", "expected", "close"],
            in: app
        )
        submitSupplementalLab(in: app)
    }

    @MainActor
    func testSupplementalUITestAuthoringLab() {
        let app = launchApp()
        openSupplementalLesson(
            trackID: "supplemental.testing.automation",
            lessonID: "supplemental.testing.ui-testing",
            in: app
        )
        composeSupplementalAssertion(
            "XCTAssertTrue(app.descendants(matching: .any)[\"lesson-complete-feedback\"].firstMatch.exists)",
            tokenIDs: ["assert", "query", "result", "exists", "close"],
            in: app
        )
        submitSupplementalLab(in: app)
    }

    @MainActor
    func testSupplementalArchitectureClassificationLab() {
        let app = launchApp()
        openSupplementalLesson(
            trackID: "supplemental.architecture.swift-learn",
            lessonID: "supplemental.architecture.dependency-direction",
            in: app
        )
        for (itemID, layer) in [
            ("construct", "app"),
            ("render", "presentation"),
            ("unlock", "domain"),
            ("persist", "data")
        ] {
            let button = app.buttons["activity-layer-\(itemID)-\(layer)"].firstMatch
            revealInteractive(button, in: app)
#if os(tvOS)
            // Layer buttons form a grid; a fixed press pattern can skip a column.
            moveFocus(to: button, in: app)
            XCUIRemote.shared.press(.select)
#else
            focusAndActivate(button)
#endif
            XCTAssertEqual(button.value as? String, "Selected")
        }
        submitSupplementalLab(in: app)
    }

    @MainActor
    private func openSupplementalLesson(
        trackID: String,
        lessonID: String,
        in app: XCUIApplication
    ) {
        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let discovery = app.buttons["open-learning-discovery"].firstMatch
        XCTAssertTrue(discovery.waitForExistence(timeout: 15))
        focusAndActivate(discovery)
        let track = app.buttons["supplemental-track-\(trackID)"].firstMatch
        XCTAssertTrue(track.waitForExistence(timeout: 10))
#if os(tvOS)
        let trackCell = focusableListCell(containing: track, in: app)
        focusAndActivate(trackCell, tvPath: [.down, .down])
#else
        focusAndActivate(track)
#endif
        XCTAssertTrue(
            app.descendants(matching: .any)["supplemental-scope-label"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        let lesson = app.buttons["supplemental-lesson-\(lessonID)"].firstMatch
        XCTAssertTrue(lesson.waitForExistence(timeout: 5))
#if os(tvOS)
        let lessonCell = focusableListCell(containing: lesson, in: app)
        focusAndActivate(lessonCell, tvPath: [.down])
#else
        focusAndActivate(lesson)
#endif
        XCTAssertTrue(
            app.descendants(matching: .any)["supplemental-lesson-detail"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func composeSupplementalAssertion(
        _ assertion: String,
        tokenIDs: [String],
        in app: XCUIApplication
    ) {
#if os(tvOS)
        for id in tokenIDs {
            let token = app.buttons["activity-token-\(id)"].firstMatch
            revealInteractive(token, in: app)
            selectOrderingFragment(token)
            XCTAssertTrue(
                app.buttons["activity-composed-\(id)"].firstMatch
                    .waitForExistence(timeout: 5)
            )
        }
#else
        let editor = app.textFields["activity-editor"].firstMatch
        revealInteractive(editor, in: app)
        activate(editor)
        editor.typeText(assertion)
#endif
    }

    /// macOS exposes static text through `value` (and on child texts), not `label`.
    @MainActor
    private func accessibleText(of element: XCUIElement) -> String {
#if os(macOS)
        let children = element.staticTexts.allElementsBoundByIndex
        return ([element] + children)
            .flatMap { [$0.label, $0.value as? String ?? ""] }
            .joined(separator: " ")
#else
        return element.label
#endif
    }

    @MainActor
    private func submitSupplementalLab(in app: XCUIApplication) {
        let submit = app.buttons["submit-supplemental-lab"].firstMatch
        revealInteractive(submit, in: app)
        XCTAssertTrue(submit.isEnabled)
#if os(tvOS)
        // After grid or token input, the fixed press pattern can miss the submit row.
        moveFocus(to: submit, in: app)
        XCUIRemote.shared.press(.select)
#else
        focusAndActivate(submit)
#endif
        let result = app.descendants(matching: .any)["supplemental-lab-result"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(accessibleText(of: result).contains("Correct"))
    }

    @MainActor
    func testGitTabCompletesFirstCommandAndUnlocksTheNext() {
        let app = launchApp()
        openTab("git-tab", label: "Git", in: app, tvDirection: .right)

        XCTAssertTrue(
            app.descendants(matching: .any)["git-learning"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        let summary = app.staticTexts["git-progress-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        assertSummary(summary, equals: "0 of 139 commands", in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["git-track-header"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        openGitResume(in: app)

        XCTAssertTrue(app.staticTexts["git-question-title"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["git-question-scenario"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["git-question-instruction"].firstMatch.exists)

        let wrong = app.buttons["git-choice-git-gc-2"].firstMatch
        revealInteractive(wrong, in: app)
        activateGitControl(wrong, in: app)
        let submit = app.buttons["submit-git-answer"].firstMatch
        revealInteractive(submit, in: app)
        activateGitControl(submit, in: app)
        let feedback = app.descendants(matching: .any)["git-answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 20))
        assertSummary(summary, equals: "0 of 139 commands", in: app)

        let retry = app.buttons["retry-git-question"].firstMatch
        revealInteractive(retry, in: app)
        activateGitControl(retry, in: app)

        let correct = app.buttons[
            "git-choice-git-bundle-create-repo-bundle-all-1"
        ].firstMatch
        revealInteractive(correct, in: app)
        activateGitControl(correct, in: app)
        revealInteractive(submit, in: app)
        activateGitControl(submit, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["git-answer-feedback"]
                .firstMatch.waitForExistence(timeout: 20)
        )
        assertSummary(summary, equals: "1 of 139 commands", in: app)

        let next = app.buttons["continue-next-git-question"].firstMatch
        revealInteractive(next, in: app)
        activateGitControl(next, in: app)
        XCTAssertTrue(app.staticTexts["git-question-title"].firstMatch.exists)
    }

    @MainActor
    func testGitTabSupportsKeyboardAndFocusNavigation() {
        let app = launchApp()
        openTab("git-tab", label: "Git", in: app, tvDirection: .right)
        openGitResume(in: app)

        let correct = app.buttons[
            "git-choice-git-bundle-create-repo-bundle-all-1"
        ].firstMatch
        XCTAssertTrue(correct.waitForExistence(timeout: 10))

#if os(macOS)
        moveKeyboardFocus(to: correct, in: app)
        app.typeKey(.space, modifierFlags: [])
#elseif os(tvOS)
        waitForFocus(on: correct)
        XCUIRemote.shared.press(.select)
#else
        activate(correct)
#endif

        let submit = app.buttons["submit-git-answer"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isEnabled)

#if os(macOS)
        moveKeyboardFocus(to: submit, in: app)
        app.typeKey(.space, modifierFlags: [])
#elseif os(tvOS)
        moveFocus(to: submit, in: app)
        XCUIRemote.shared.press(.select)
#else
        activate(submit)
#endif

        XCTAssertTrue(
            app.descendants(matching: .any)["git-answer-feedback"]
                .firstMatch.waitForExistence(timeout: 20)
        )
        assertSummary(
            app.staticTexts["git-progress-summary"].firstMatch,
            equals: "1 of 139 commands",
            in: app
        )
    }

    @MainActor
    func testGitCategoryDetailExplainsLockedCommand() {
        let app = launchApp()
        openTab("git-tab", label: "Git", in: app, tvDirection: .right)

        let category = app.descendants(matching: .any)[
            "open-git-category-git.maintenance"
        ].firstMatch
        revealInteractive(category, in: app)
        activateGitControl(category, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["git-category-detail-git.maintenance"]
                .firstMatch.waitForExistence(timeout: 5)
        )

        let lockedCommand = app.descendants(matching: .any)[
            "git-command-row-git.maintenance.gc"
        ].firstMatch
        revealInteractive(lockedCommand, in: app)
        activateGitControl(lockedCommand, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)[
                "git-command-locked-reason-git.maintenance.gc"
            ].firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testGitResetClearsGitProgressAndKeepsSwiftProgress() throws {
        let lesson = try XCTUnwrap(loadLessonExpectations().first)
        let app = launchApp(persistsData: true)

        openTab("journey-tab", label: "Journey", in: app, tvDirection: .left)
        let startLesson = app.buttons["start-lesson-\(lesson.id)"].firstMatch
        openJourneyLesson(startLesson, in: app)
        let correctChoice = app.buttons["choice-\(lesson.correctChoiceID)"].firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
        revealInteractive(correctChoice, in: app)
        select(
            correctChoice,
            firstChoice: app.buttons["choice-\(lesson.choices[0].id)"],
            choiceIndex: lesson.correctChoiceIndex
        )
        let submitLesson = app.buttons["submit-answer"].firstMatch
        revealInteractive(submitLesson, in: app)
        activate(submitLesson)
        XCTAssertTrue(
            app.descendants(matching: .any)["lesson-complete-feedback"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        dismissAchievementOverlays(in: app)
        popToJourneyRoot(in: app)

        openTab("git-tab", label: "Git", in: app, tvDirection: .right)
        let summary = app.staticTexts["git-progress-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        openGitResume(in: app)
        let correct = app.buttons[
            "git-choice-git-bundle-create-repo-bundle-all-1"
        ].firstMatch
        revealInteractive(correct, in: app)
        activateGitControl(correct, in: app)
        let submitGit = app.buttons["submit-git-answer"].firstMatch
        revealInteractive(submitGit, in: app)
        activateGitControl(submitGit, in: app)
        assertSummary(summary, equals: "1 of 139 commands", in: app)

        popToGitRoot(in: app)

        let reset = app.buttons["reset-git-progress"].firstMatch
        revealInteractive(reset, in: app)
        activateGitControl(reset, in: app)
        let cancel = confirmationButton(labeled: "Cancel", in: app)
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        activateGitControl(cancel, in: app)
        assertSummary(summary, equals: "1 of 139 commands", in: app)

        revealInteractive(reset, in: app)
        activateGitControl(reset, in: app)
        let confirm = confirmationButton(labeled: "Reset Git Progress", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        activateResetConfirmation(confirm)

        XCTAssertTrue(
            app.descendants(matching: .any)["git-progress-reset-success"]
                .firstMatch.waitForExistence(timeout: 10)
        )
        assertSummary(summary, equals: "0 of 139 commands", in: app)

        // Relaunch instead of popping the pushed lesson: the Journey root is
        // then deterministic on every platform, and persistence is re-proven.
        app.terminate()
        let relaunched = launchApp(persistsData: true, resetsPersistentData: false)
        openTab("journey-tab", label: "Journey", in: relaunched, tvDirection: .left)
        let restoredLesson = relaunched.buttons["start-lesson-\(lesson.id)"].firstMatch
        reveal(restoredLesson, in: relaunched, maxMoves: 40)
        assertValue(restoredLesson, equals: "Completed", in: relaunched)

        openTab("git-tab", label: "Git", in: relaunched, tvDirection: .right)
        let restoredSummary = relaunched.staticTexts["git-progress-summary"].firstMatch
        XCTAssertTrue(restoredSummary.waitForExistence(timeout: 10))
        assertSummary(restoredSummary, equals: "0 of 139 commands", in: relaunched)
    }

    @MainActor
    func testGitFinalCommandShowsCompletionCard() {
        let app = launchApp(gitFinalFixture: true)
        openTab("git-tab", label: "Git", in: app, tvDirection: .right)

        let summary = app.staticTexts["git-progress-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        assertSummary(summary, equals: "138 of 139 commands", in: app)
        openGitResume(in: app)

        let correct = app.buttons["git-choice-git-push-tags-1"].firstMatch
        revealInteractive(correct, in: app)
        activateGitControl(correct, in: app)
        let submit = app.buttons["submit-git-answer"].firstMatch
        revealInteractive(submit, in: app)
        activateGitControl(submit, in: app)
        assertSummary(summary, equals: "139 of 139 commands", in: app)

        let finish = app.buttons["continue-next-git-question"].firstMatch
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        XCTAssertEqual(finish.label, "Finish Git Track")
        revealInteractive(finish, in: app, maxMoves: 40)
        activateGitControl(finish, in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["git-track-complete"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testGitResetFailureKeepsProgressAndShowsAccessibleError() {
        let app = launchApp(failsGitReset: true)
        openTab("git-tab", label: "Git", in: app, tvDirection: .right)

        let summary = app.staticTexts["git-progress-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        openGitResume(in: app)
        let correct = app.buttons[
            "git-choice-git-bundle-create-repo-bundle-all-1"
        ].firstMatch
        revealInteractive(correct, in: app)
        activateGitControl(correct, in: app)
        let submit = app.buttons["submit-git-answer"].firstMatch
        revealInteractive(submit, in: app)
        activateGitControl(submit, in: app)
        assertSummary(summary, equals: "1 of 139 commands", in: app)

        popToGitRoot(in: app)

        let reset = app.buttons["reset-git-progress"].firstMatch
        revealInteractive(reset, in: app)
        activateGitControl(reset, in: app)
        let confirm = confirmationButton(labeled: "Reset Git Progress", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        activateResetConfirmation(confirm)

        let error = app.descendants(matching: .any)[
            "git-progress-reset-error"
        ].firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertTrue(
            accessibleText(of: error).contains("Git reset is unavailable")
        )
        assertSummary(summary, equals: "1 of 139 commands", in: app)
    }

    @MainActor
    func testGitProgressSurvivesRelaunch() {
        let app = launchApp(persistsData: true)
        openTab("git-tab", label: "Git", in: app, tvDirection: .right)
        openGitResume(in: app)

        let correct = app.buttons[
            "git-choice-git-bundle-create-repo-bundle-all-1"
        ].firstMatch
        revealInteractive(correct, in: app)
        activateGitControl(correct, in: app)
        let submit = app.buttons["submit-git-answer"].firstMatch
        revealInteractive(submit, in: app)
        activateGitControl(submit, in: app)
        assertSummary(
            app.staticTexts["git-progress-summary"].firstMatch,
            equals: "1 of 139 commands",
            in: app
        )
        app.terminate()

        let relaunched = launchApp(
            persistsData: true,
            resetsPersistentData: false
        )
        openTab("git-tab", label: "Git", in: relaunched, tvDirection: .right)
        let summary = relaunched.staticTexts["git-progress-summary"].firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        assertSummary(summary, equals: "1 of 139 commands", in: relaunched)
    }

    @MainActor
    func testProfileDataDiagnosticsProvidesExportEntry() {
        let app = launchApp()
        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)

        let diagnostics = app.buttons["profile-data-diagnostics"].firstMatch
        revealInteractive(diagnostics, in: app)
        focusAndActivate(diagnostics)

        XCTAssertTrue(
            app.descendants(matching: .any)["learning-data-diagnostics-screen"]
                .firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["export-learning-summary"]
                .firstMatch.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func launchApp(
        skipIntro: Bool = true,
        persistsData: Bool = false,
        resetsPersistentData: Bool = true,
        reviewFixture: Bool = false,
        activityFixture: Bool = false,
        codeOrderingFixture: Bool = false,
        activityKind: String? = nil,
        bossFixture: Bool = false,
        levelCompletionFixture: Bool = false,
        projectFixture: Bool = false,
        gitFinalFixture: Bool = false,
        failsGitReset: Bool = false,
        failsFirstBossCompletionSave: Bool = false,
        discoveryQuery: String = "",
        rightToLeft: Bool = false,
        fixedChoiceOrder: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        // The suite reaches answers by position on tvOS and by authored index
        // elsewhere, so it pins the authored order unless a test is checking
        // the shuffle itself.
        if fixedChoiceOrder {
            app.launchArguments.append("--ui-testing-fixed-choice-order")
        }
        if skipIntro {
            app.launchArguments.append("--skip-intro")
        }
        if persistsData {
            app.launchArguments.append("--ui-testing-persistent")
            if resetsPersistentData {
                app.launchArguments.append("--reset-ui-testing-data")
            }
        }
        if reviewFixture {
            app.launchArguments.append("--ui-testing-review-fixture")
        }
        if activityFixture {
            app.launchArguments.append("--ui-testing-activity-fixture")
        }
        if codeOrderingFixture {
            app.launchArguments.append("--ui-testing-code-ordering-fixture")
        }
        if let activityKind {
            app.launchArguments.append("--ui-testing-activity-kind=\(activityKind)")
        }
        if bossFixture {
            app.launchArguments.append("--ui-testing-boss-fixture")
        }
        if levelCompletionFixture {
            app.launchArguments.append("--ui-testing-level-completion-fixture")
        }
        if projectFixture {
            app.launchArguments.append("--ui-testing-project-fixture")
        }
        if gitFinalFixture {
            app.launchArguments.append("--ui-testing-git-final-fixture")
        }
        if failsGitReset {
            app.launchArguments.append("--ui-testing-fail-git-reset")
        }
        if failsFirstBossCompletionSave {
            app.launchArguments.append(
                "--ui-testing-fail-first-boss-completion-save"
            )
        }
        if discoveryQuery.isEmpty == false {
            app.launchArguments.append("--ui-testing-discovery-query=\(discoveryQuery)")
        }
        if rightToLeft {
            app.launchArguments.append("--ui-testing-rtl")
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

    /// Returns from a pushed lesson to the Journey root so its rows are visible.
    @MainActor
    private func popToJourneyRoot(in app: XCUIApplication) {
        let root = app.descendants(matching: .any)["journey-review-summary"]
            .firstMatch
#if os(tvOS)
        XCUIRemote.shared.press(.menu)
#else
        for _ in 0..<3 {
            if root.waitForExistence(timeout: 1) { break }
            guard tapBackButton(in: app) else { break }
        }
#endif
        XCTAssertTrue(root.waitForExistence(timeout: 5))
    }

    @MainActor
    private func openGitResume(in app: XCUIApplication) {
        let resume = app.buttons["resume-git-command"].firstMatch
        revealInteractive(resume, in: app)
        activateGitControl(resume, in: app)
        XCTAssertTrue(
            app.staticTexts["git-question-title"].firstMatch
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func activateGitControl(
        _ element: XCUIElement,
        in app: XCUIApplication
    ) {
#if os(tvOS)
        moveFocus(to: element, in: app)
        XCUIRemote.shared.press(.select)
#else
        app.activate()
        tapReliably(element)
#endif
    }

#if !os(tvOS)
    /// `tap()` resolves a hit point some controls ignore, so a tap that reports
    /// success can leave the app unchanged. A centre coordinate does land.
    @MainActor
    private func tapReliably(_ element: XCUIElement) {
        guard element.exists else {
            XCTFail("Cannot tap a control that does not exist")
            return
        }
        // A coordinate tap on an off-screen control lands somewhere else
        // entirely — often the tab bar — so only use it once the control is
        // actually on screen.
        if element.isHittable {
            element.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
            ).tap()
        } else {
            element.tap()
        }
    }
#endif

    @MainActor
    private func popToGitRoot(in app: XCUIApplication) {
        let root = app.descendants(matching: .any)["resume-git-command"]
            .firstMatch
#if os(tvOS)
        XCUIRemote.shared.press(.menu)
#else
        for _ in 0..<3 {
            if root.waitForExistence(timeout: 1) { break }
            guard tapBackButton(in: app) else { break }
        }
#endif
        XCTAssertTrue(root.waitForExistence(timeout: 5))
    }

#if !os(tvOS)
    @MainActor
    private func tapBackButton(in app: XCUIApplication) -> Bool {
        let backPredicate = NSPredicate(
            format: "label == %@ OR identifier == %@",
            "Back",
            "chevron.backward"
        )
        let labeledBack = app.buttons.matching(backPredicate).firstMatch
        if labeledBack.waitForExistence(timeout: 1), labeledBack.isHittable {
            tapReliably(labeledBack)
            return true
        }

        let navigationBack = app.navigationBars.buttons.element(boundBy: 0)
        if navigationBack.waitForExistence(timeout: 1), navigationBack.isHittable {
            tapReliably(navigationBack)
            return true
        }

        return false
    }
#endif

    /// A confirmation dialog renders as a sheet on iOS and an alert elsewhere,
    /// and the system supplies its buttons, so they are matched by label.
    @MainActor
    private func confirmationButton(
        labeled label: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let sheetButton = app.sheets.buttons[label].firstMatch
        if sheetButton.exists { return sheetButton }
        let alertButton = app.alerts.buttons[label].firstMatch
        if alertButton.exists { return alertButton }
        return app.buttons.matching(identifier: label).element(boundBy: 0)
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
        // A SwiftUI tab surfaces as a radio button on macOS, and only some
        // builds expose it as a button, so try both before the identifier.
        let radioTab = app.radioButtons[label].firstMatch
        let labeledTab = app.buttons[label].firstMatch
        let tab: XCUIElement
        if radioTab.waitForExistence(timeout: 5) {
            tab = radioTab
        } else if labeledTab.waitForExistence(timeout: 5) {
            tab = labeledTab
        } else {
            tab = app.descendants(matching: .any)[identifier].firstMatch
        }
#else
        let tabBarButton = app.tabBars.buttons[label].firstMatch
        let identifiedTab = app.descendants(matching: .any)[identifier].firstMatch
        let tab = tabBarButton.waitForExistence(timeout: 5)
            ? tabBarButton
            : identifiedTab.waitForExistence(timeout: 5)
                ? identifiedTab
                : app.buttons[label].firstMatch
#endif
        XCTAssertTrue(tab.waitForExistence(timeout: 5))

#if os(tvOS)
        let content = selectedTabContent(identifier: identifier, in: app)
        // Moving focus presses directional buttons, which on an open tab walks
        // into its content and can open a row. Leave a tab that is already
        // showing alone.
        guard !content.waitForExistence(timeout: 5) else { return }

        let remote = XCUIRemote.shared
        let tabs = ["journey-tab", "git-tab", "profile-tab"].map {
            app.descendants(matching: .any)[$0].firstMatch
        }

        for _ in 0..<12 where !tabs.contains(where: \.hasFocus) {
            remote.press(.up)
        }

        for _ in 0..<2 where !tab.hasFocus {
            remote.press(tvDirection == .left ? .left : .right)
            let focused = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "hasFocus == true"),
                object: tab
            )
            if XCTWaiter.wait(for: [focused], timeout: 0.5) == .completed {
                break
            }
        }
        if !tab.hasFocus {
            // The fixed press sequence assumes the tab bar is one step away.
            // When it is not, search for the tab with the focus engine.
            moveFocus(to: tab, in: app)
        }
        if tab.hasFocus {
            remote.press(.select)
        }
        XCTAssertTrue(
            content.waitForExistence(timeout: 20),
            "Could not open the \(identifier) tab"
        )
#else
        // A tap on a tab item is unreliable: `tap()` resolves a hit point the
        // tab bar ignores, and even a centre coordinate is dropped while the
        // catalog is still settling. Alternate both until the tab changes.
        let content = selectedTabContent(identifier: identifier, in: app)
        var switched = content.exists
        for _ in 0..<4 where !switched {
            tab.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
            ).tap()
            if content.waitForExistence(timeout: 8) {
                switched = true
                break
            }
            tab.tap()
            switched = content.waitForExistence(timeout: 8)
        }
        XCTAssertTrue(switched, "Could not open the \(identifier) tab")
#endif
    }

    /// Each tab's own content. macOS exposes no `navigationBar` for a
    /// `NavigationStack`, so matching one there finds nothing; tvOS does not
    /// surface the journey scroll view's identifier, so it needs the bar.
    @MainActor
    private func selectedTabContent(
        identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        switch identifier {
        case "profile-tab":
            return app.descendants(matching: .any)["profile-screen"].firstMatch
        case "git-tab":
            return app.descendants(matching: .any)["git-learning"].firstMatch
        default:
#if os(tvOS)
            // tvOS does not surface the journey scroll view's identifier, so
            // the navigation bar remains the only reliable marker there.
            return app.navigationBars.matching(
                NSPredicate(
                    format: "identifier IN %@",
                    ["Swift Learn", "Practice", "Boss Challenge", "Guided Project"]
                )
            ).firstMatch
#else
            return app.descendants(matching: .any)["learning-journey"].firstMatch
#endif
        }
    }

    @MainActor
    private func assertSummary(
        _ identifiedElement: XCUIElement,
        equals expectedText: String,
        in app: XCUIApplication
    ) {
        // A tab's shell appears before its catalog finishes loading, and the
        // Git catalog is 139 commands, so five seconds is not enough.
        XCTAssertTrue(identifiedElement.waitForExistence(timeout: 20))

#if os(macOS)
        XCTAssertTrue(app.staticTexts[expectedText].firstMatch.waitForExistence(timeout: 20))
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
            let labelSegments = element.label
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if labelSegments.contains(expectedValue) {
                return
            }
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
    /// `maxMoves` bounds each scroll direction; long lazy lists (the 41-card
    /// achievement grid) need more than the default.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxMoves: Int = 12) {
        if element.waitForExistence(timeout: 2) {
            return
        }

#if os(macOS)
        scrollDown(until: element, in: app, requiresHittable: false, maxMoves: maxMoves)
#elseif os(tvOS)
        let remote = XCUIRemote.shared
        for _ in 0..<max(20, maxMoves) where !element.exists {
            remote.press(.down)
        }
        for _ in 0..<max(20, maxMoves) where !element.exists {
            remote.press(.up)
        }
#else
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))

        for _ in 0..<maxMoves where !element.exists {
            app.swipeUp()
        }

        for _ in 0..<maxMoves where !element.exists {
            app.swipeDown()
        }
#endif

        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }

    @MainActor
    private func revealInteractive(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxMoves: Int = 12
    ) {
#if os(macOS)
        scrollDown(
            until: element,
            in: app,
            requiresHittable: true,
            maxMoves: maxMoves
        )
#elseif os(tvOS)
        reveal(element, in: app)
#else
        _ = element.waitForExistence(timeout: 2)
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))

        for _ in 0..<maxMoves where !element.isHittable {
            app.swipeUp()
        }

        for _ in 0..<maxMoves where !element.isHittable {
            app.swipeDown()
        }

        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
#endif
    }

    @MainActor
    private func scrollToTop(in app: XCUIApplication) {
#if os(macOS)
        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            XCTFail("Expected a scroll view while returning to the top")
            return
        }

        app.activate()
        let scrollCoordinate = app.windows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)
        )
        for _ in 0..<16 {
            scrollCoordinate.scroll(byDeltaX: 0, deltaY: 300)
        }
#elseif !os(tvOS)
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))
        for _ in 0..<16 {
            app.swipeDown()
        }
#endif
    }

#if os(macOS)
    @MainActor
    private func moveKeyboardFocus(
        to element: XCUIElement,
        in app: XCUIApplication
    ) {
        app.activate()
        for _ in 0..<24 where !hasKeyboardFocus(element) {
            app.typeKey(.tab, modifierFlags: [])
        }
        if !hasKeyboardFocus(element) {
            tapReliably(element)
        }
    }

    @MainActor
    private func hasKeyboardFocus(_ element: XCUIElement) -> Bool {
        let focused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasKeyboardFocus == true"),
            object: element
        )
        return XCTWaiter.wait(for: [focused], timeout: 0.2) == .completed
    }

    @MainActor
    private func scrollDown(
        until element: XCUIElement,
        in app: XCUIApplication,
        requiresHittable: Bool,
        maxMoves: Int = 12
    ) {
        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            XCTFail("Expected a scroll view while revealing \(element)")
            return
        }

        app.activate()
        let scrollCoordinate = app.windows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)
        )
        for _ in 0..<maxMoves {
            if element.exists && (!requiresHittable || element.isHittable) {
                break
            }
            scrollCoordinate.scroll(byDeltaX: 0, deltaY: -300)
        }

        for _ in 0..<maxMoves {
            if element.exists && (!requiresHittable || element.isHittable) {
                break
            }
            scrollCoordinate.scroll(byDeltaX: 0, deltaY: 300)
        }

        XCTAssertTrue(element.waitForExistence(timeout: 5))
        if requiresHittable {
            XCTAssertTrue(element.isHittable)
        }
    }
#endif

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
    private func focusableListCell(
        containing button: XCUIElement,
        in app: XCUIApplication
    ) -> XCUIElement {
        let cell = app.cells.containing(
            .button,
            identifier: button.identifier
        ).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        return cell
    }

    /// Steers focus toward `element` by comparing its frame with the focused element's frame.
    /// When a press does not move focus, the other axis is tried next.
    @MainActor
    private func moveFocus(
        to element: XCUIElement,
        in app: XCUIApplication,
        maxMoves: Int = 60
    ) {
        let remote = XCUIRemote.shared
        var previousFrame: CGRect?
        var prefersHorizontal = false
        for _ in 0..<maxMoves where !element.hasFocus {
            guard let current = focusedFrame(in: app) else {
                remote.press(.down)
                continue
            }
            if current == previousFrame {
                prefersHorizontal.toggle()
            }
            previousFrame = current
            let target = element.frame
            let vertical: XCUIRemote.Button? = target.minY >= current.maxY - 1
                ? .down
                : target.maxY <= current.minY + 1 ? .up : nil
            let horizontal: XCUIRemote.Button? = target.maxX <= current.minX + 1
                ? .left
                : target.minX >= current.maxX - 1 ? .right : nil
            let primary = prefersHorizontal ? horizontal ?? vertical : vertical ?? horizontal
            remote.press(primary ?? .down)
        }
        XCTAssertTrue(element.hasFocus)
    }

    /// Frame of the smallest element reporting focus, read from one hierarchy snapshot.
    @MainActor
    private func focusedFrame(in app: XCUIApplication) -> CGRect? {
        guard let root = try? app.snapshot() else { return nil }
        var pending: [XCUIElementSnapshot] = [root]
        var focused: CGRect?
        while let node = pending.popLast() {
            if node.hasFocus {
                let area = node.frame.width * node.frame.height
                if focused.map({ area < $0.width * $0.height }) ?? true {
                    focused = node.frame
                }
            }
            pending.append(contentsOf: node.children)
        }
        return focused
    }

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

    /// Display order of the answers, read from the accessibility hierarchy.
    /// Hierarchy order is what the learner sees and, unlike element frames, it
    /// does not shift when the question scrolls.
    @MainActor
    private func displayedChoiceIDs(
        prefix: String,
        ids: [String],
        in app: XCUIApplication
    ) -> [String] {
        let expected = Set(ids.map { "\(prefix)\($0)" })
        guard let root = try? app.snapshot() else { return [] }
        var ordered: [String] = []
        func walk(_ node: XCUIElementSnapshot) {
            let identifier = node.identifier
            if expected.contains(identifier), !ordered.contains(identifier) {
                ordered.append(identifier)
            }
            for child in node.children {
                walk(child)
            }
        }
        walk(root)
        return ordered.map { String($0.dropFirst(prefix.count)) }
    }

    /// Activates a control by searching for it with the focus engine instead of
    /// pressing a fixed number of times, which a shuffled question breaks.
    @MainActor
    private func activateByFocus(_ element: XCUIElement, in app: XCUIApplication) {
#if os(tvOS)
        moveFocus(to: element, in: app)
        XCUIRemote.shared.press(.select)
#elseif os(macOS)
        app.activate()
        element.tap()
#else
        element.tap()
#endif
    }

    /// Selects an answer without assuming its position, which a shuffled
    /// question does not guarantee.
    @MainActor
    private func selectByFocus(_ element: XCUIElement, in app: XCUIApplication) {
        activateByFocus(element, in: app)
#if os(tvOS)
        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Selected"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 2), .completed)
#endif
    }

    private func loadLessonExpectations() throws -> [LessonExpectation] {
        let catalog = try loadCatalogExpectation()
        let lessons = catalog.levels.flatMap(\.lessons)
        XCTAssertEqual(lessons.count, 486)
        return lessons
    }

    private func loadCatalogExpectation() throws -> LearningCatalogExpectation {
        let testBundle = Bundle(for: Swift_LearnUITests.self)
        let runnerPlugInURL = Bundle.main.builtInPlugInsURL?
            .appendingPathComponent("Swift LearnUITests.xctest", isDirectory: true)
        let runnerTestBundle = runnerPlugInURL.flatMap(Bundle.init(url:))
        // Simulator and Mac runners can read the repository copy. It covers the case where the
        // installed runner container was reaped (seen under `containermanagerd/Dead`).
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Swift Learn/Data/Content/swift-6.4-beta-foundations.json")
        let fileManager = FileManager.default
        let resourceURL = try XCTUnwrap(
            [
                testBundle.url(forResource: "swift-6.4-beta-foundations", withExtension: "json"),
                runnerTestBundle?.url(
                    forResource: "swift-6.4-beta-foundations",
                    withExtension: "json"
                ),
                sourceURL
            ]
            .compactMap { $0 }
            .first { fileManager.isReadableFile(atPath: $0.path) },
            "Missing UI-test catalog fixture in \(testBundle.bundleURL.path), runner plug-ins at \(runnerPlugInURL?.path ?? "unavailable"), or \(sourceURL.path)"
        )
        return try JSONDecoder().decode(
            LearningCatalogExpectation.self,
            from: Data(contentsOf: resourceURL)
        )
    }

#if os(tvOS)
    @MainActor
    private func assertInitialChoiceFocus(
        _ choice: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Observe app-driven step focus before the navigation helper can conceal a regression.
        let focused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasFocus == true"),
            object: choice
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [focused], timeout: 5),
            .completed,
            "New activity must focus its first choice: \(choice.identifier)",
            file: file,
            line: line
        )
    }
#endif

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
    private func selectOrderingFragment(_ element: XCUIElement) {
#if os(tvOS)
        let remote = XCUIRemote.shared
        for _ in 0..<12 where !element.hasFocus {
            remote.press(.up)
        }
        for _ in 0..<12 where !element.hasFocus {
            remote.press(.down)
        }
        XCTAssertTrue(element.hasFocus)
        remote.press(.select)
#else
        activate(element)
#endif
    }

    @MainActor
    private func enterConstrainedExpression(
        lesson: LessonExpectation,
        in app: XCUIApplication
    ) {
#if os(tvOS)
        XCTAssertEqual(lesson.canonicalTokenIDs.count, 4)
        for id in lesson.canonicalTokenIDs {
            let token = app.buttons["activity-token-\(id)"].firstMatch
            revealInteractive(token, in: app)
            // Journey places tokens below the prompt and code; steer focus by frame.
            moveFocus(to: token, in: app)
            XCUIRemote.shared.press(.select)
            XCTAssertTrue(
                app.buttons["activity-composed-\(id)"].firstMatch
                    .waitForExistence(timeout: 5)
            )
        }
#else
        let editor = app.textFields["activity-editor"].firstMatch
        revealInteractive(editor, in: app)
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText("Double(three)")
#endif
    }

    /// Opens a Journey lesson row. On tvOS, rows deeper than the shared
    /// 20-press `activate` budget need a bidirectional focus search.
    @MainActor
    private func openJourneyLesson(_ startLesson: XCUIElement, in app: XCUIApplication) {
        reveal(startLesson, in: app)
#if os(tvOS)
        let remote = XCUIRemote.shared
        for _ in 0..<60 where !startLesson.hasFocus {
            remote.press(.down)
        }
        for _ in 0..<60 where !startLesson.hasFocus {
            remote.press(.up)
        }
        XCTAssertTrue(startLesson.hasFocus)
        remote.press(.select)
#else
        activate(startLesson)
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
#elseif os(macOS)
        XCUIApplication().activate()
        element.tap()
#else
        element.tap()
#endif
    }

    @MainActor
    private func activateResetConfirmation(_ element: XCUIElement) {
#if os(tvOS)
        let remote = XCUIRemote.shared
        remote.press(.up)
        remote.press(.select)
#else
        element.tap()
#endif
    }

    @MainActor
    private func activateIntroPrimary(
        _ element: XCUIElement,
        in app: XCUIApplication
    ) {
#if os(macOS)
        app.activate()
        app.typeKey(.return, modifierFlags: [])
#else
        activate(element)
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
        let id: String
        let title: String
        let lessons: [LessonExpectation]
    }
}

private struct LessonExpectation: Decodable {
    let id: String
    let title: String
    let activityType: String
    let correctChoiceID: String
    let correctOrderIDs: [String]
    let canonicalTokenIDs: [String]
    let choices: [Choice]

    var correctChoiceIndex: Int {
        choices.firstIndex { $0.id == correctChoiceID } ?? 0
    }

    struct Choice: Decodable {
        let id: String
    }

    private struct Activity: Decodable {
        let type: String
        let correctChoiceID: String?
        let correctOrderIDs: [String]?
        let choices: [Choice]?
        let fragments: [Choice]?
        let tokens: [Choice]?
        let canonicalTokenIDs: [String]?
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case correctChoiceID
        case choices
        case activity
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        if let activity = try container.decodeIfPresent(
            Activity.self,
            forKey: .activity
        ) {
            activityType = activity.type
            correctChoiceID = activity.correctChoiceID ?? ""
            correctOrderIDs = activity.correctOrderIDs ?? []
            canonicalTokenIDs = activity.canonicalTokenIDs ?? []
            choices = activity.choices ?? activity.fragments ?? activity.tokens ?? []
        } else {
            activityType = "missingCode"
            correctOrderIDs = []
            canonicalTokenIDs = []
            correctChoiceID = try container.decode(
                String.self,
                forKey: .correctChoiceID
            )
            choices = try container.decode([Choice].self, forKey: .choices)
        }

        guard !choices.isEmpty,
              (activityType == "codeOrdering"
                  ? correctOrderIDs.count == choices.count
                  : activityType == "constrainedEditing"
                      ? canonicalTokenIDs.count == choices.count
                      : choices.contains(where: { $0.id == correctChoiceID })) else {
            throw DecodingError.dataCorruptedError(
                forKey: .choices,
                in: container,
                debugDescription: "Lesson activity choices are invalid."
            )
        }
    }
}
