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
        reveal(bossAchievement, in: app)
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
        assertSummary(
            app.staticTexts["learning-project-result-summary"].firstMatch,
            equals: "3 of 3 requirements validated",
            in: app
        )

        openTab("profile-tab", label: "Profile", in: app, tvDirection: .right)
        let projectAchievement = app.descendants(matching: .any)[
            "achievement-card-achievement.project.swift-foundations"
        ].firstMatch
        reveal(projectAchievement, in: app)
        assertAchievement(
            projectAchievement,
            label: "Build a Practice Setup, Earned",
            value: "Earned, 1 of 1"
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
        XCTAssertTrue(openLevel.waitForExistence(timeout: 5))
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
        dismissSoftwareKeyboardIfPresented(in: app)
#endif
        focusAndActivate(
            track,
            tvPath: [.down, .down]
        )
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
        focusAndActivate(
            lesson,
            tvPath: Array(repeating: .up, count: 48)
        )

        let correctChoice = app.buttons["supplemental-choice-correct"].firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5))
        focusAndActivate(correctChoice)

        let submit = app.buttons["submit-supplemental-practice"].firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        focusAndActivate(submit)
        XCTAssertTrue(
            app.descendants(matching: .any)["supplemental-practice-result"]
                .firstMatch.waitForExistence(timeout: 5)
        )
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
        reviewFixture: Bool = false,
        activityFixture: Bool = false,
        bossFixture: Bool = false,
        projectFixture: Bool = false,
        failsFirstBossCompletionSave: Bool = false,
        discoveryQuery: String = "",
        rightToLeft: Bool = false
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
        if activityFixture {
            app.launchArguments.append("--ui-testing-activity-fixture")
        }
        if bossFixture {
            app.launchArguments.append("--ui-testing-boss-fixture")
        }
        if projectFixture {
            app.launchArguments.append("--ui-testing-project-fixture")
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
        if tab.hasFocus {
            remote.press(.select)
        } else {
            XCTAssertTrue(
                selectedTabContent(identifier: identifier, in: app)
                    .waitForExistence(timeout: 5)
            )
        }
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
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        if element.waitForExistence(timeout: 2) {
            return
        }

#if os(macOS)
        scrollDown(until: element, in: app, requiresHittable: false)
#elseif os(tvOS)
        let remote = XCUIRemote.shared
        for _ in 0..<20 where !element.exists {
            remote.press(.down)
        }
        for _ in 0..<20 where !element.exists {
            remote.press(.up)
        }
#else
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))

        for _ in 0..<12 where !element.exists {
            app.swipeUp()
        }

        for _ in 0..<12 where !element.exists {
            app.swipeDown()
        }
#endif

        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }

    @MainActor
    private func revealInteractive(_ element: XCUIElement, in app: XCUIApplication) {
#if os(macOS)
        scrollDown(until: element, in: app, requiresHittable: true)
#elseif os(tvOS)
        reveal(element, in: app)
#else
        _ = element.waitForExistence(timeout: 2)
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))

        for _ in 0..<12 where !element.isHittable {
            app.swipeUp()
        }

        for _ in 0..<12 where !element.isHittable {
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
    private func scrollDown(
        until element: XCUIElement,
        in app: XCUIApplication,
        requiresHittable: Bool
    ) {
        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            XCTFail("Expected a scroll view while revealing \(element)")
            return
        }

        app.activate()
        let scrollCoordinate = app.windows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)
        )
        for _ in 0..<12 {
            if element.exists && (!requiresHittable || element.isHittable) {
                break
            }
            scrollCoordinate.scroll(byDeltaX: 0, deltaY: -300)
        }

        for _ in 0..<12 {
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
    private func dismissSoftwareKeyboardIfPresented(in app: XCUIApplication) {
        if app.keyboards.firstMatch.waitForExistence(timeout: 5) {
            XCUIRemote.shared.press(.menu)
        }
    }

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

    @MainActor
    private func selectedTabContent(
        identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        if identifier == "profile-tab" {
            return app.descendants(matching: .any)["profile-screen"].firstMatch
        }

        return app.navigationBars.matching(
            NSPredicate(
                format: "identifier IN %@",
                ["Swift Learn", "Practice", "Boss Challenge", "Guided Project"]
            )
        ).firstMatch
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

    private func loadLessonExpectations() throws -> [LessonExpectation] {
        let catalog = try loadCatalogExpectation()
        let lessons = catalog.levels.flatMap(\.lessons)
        XCTAssertEqual(lessons.count, 486)
        return lessons
    }

    private func loadCatalogExpectation() throws -> LearningCatalogExpectation {
        let resourceURL = try XCTUnwrap(
            Bundle(for: Swift_LearnUITests.self).url(
                forResource: "swift-6.4-beta-foundations",
                withExtension: "json"
            )
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
    let choices: [Choice]

    var correctChoiceIndex: Int {
        choices.firstIndex { $0.id == correctChoiceID } ?? 0
    }

    struct Choice: Decodable {
        let id: String
    }

    private struct Activity: Decodable {
        let type: String
        let correctChoiceID: String
        let choices: [Choice]
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
            correctChoiceID = activity.correctChoiceID
            choices = activity.choices
        } else {
            activityType = "missingCode"
            correctChoiceID = try container.decode(
                String.self,
                forKey: .correctChoiceID
            )
            choices = try container.decode([Choice].self, forKey: .choices)
        }

        guard !choices.isEmpty,
              choices.contains(where: { $0.id == correctChoiceID }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .choices,
                in: container,
                debugDescription: "Lesson activity choices are invalid."
            )
        }
    }
}
