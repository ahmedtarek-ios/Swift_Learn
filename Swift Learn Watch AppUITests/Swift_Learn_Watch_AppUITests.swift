import XCTest

final class Swift_Learn_Watch_AppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDashboardShowsProgressAndOpensNextLesson() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-watch-snapshot"]
        app.launch()

        XCTAssertTrue(element("watch-home", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["watch-learner-name"].exists)
        XCTAssertTrue(app.staticTexts["watch-progress-summary"].exists)
        XCTAssertTrue(app.staticTexts["watch-review-count"].exists)
        XCTAssertTrue(app.staticTexts["watch-sync-status"].exists)

        let nextLesson = app.buttons["watch-next-lesson"]
        XCTAssertTrue(nextLesson.exists)
        XCTAssertEqual(nextLesson.label, "Next lesson, Constants and Variables")
        nextLesson.tap()

        XCTAssertTrue(
            element("watch-next-lesson-detail", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["watch-next-lesson-title"].exists)
        XCTAssertTrue(app.staticTexts["watch-next-lesson-objective"].exists)
    }

    @MainActor
    func testDashboardShowsQueuedOfflineChange() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-watch-snapshot",
            "--ui-testing-watch-pending-sync"
        ]
        app.launch()

        let status = app.staticTexts["watch-sync-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "1 change waiting to sync")
    }

    @MainActor
    func testDashboardShowsEmptySyncState() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-watch-empty"]
        app.launch()

        let emptyState = element("watch-empty-state", in: app)
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
        XCTAssertEqual(
            emptyState.label,
            "Open Swift Learn on iPhone. "
                + "Your progress will appear after the first sync."
        )
    }

    @MainActor
    func testDashboardShowsSyncError() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-watch-error"]
        app.launch()

        let errorState = element("watch-sync-error", in: app)
        XCTAssertTrue(errorState.waitForExistence(timeout: 5))
        XCTAssertEqual(errorState.label, "Sync unavailable. Snapshot unavailable")
    }

    @MainActor
    func testProgressDetailShowsLevelAndMastery() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-watch-snapshot"]
        app.launch()

        tapButton("watch-progress-entry", in: app)
        XCTAssertTrue(
            element("watch-progress-detail", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.staticTexts["watch-progress-level-title"].label,
            "Level 1 · Values & Expressions"
        )
        XCTAssertEqual(
            app.staticTexts["watch-progress-level-summary"].label,
            "12 of 53 lessons in this level"
        )

        let mastered = element("watch-progress-row-mastered", in: app)
        XCTAssertTrue(mastered.exists)
        XCTAssertEqual(mastered.label, "Mastered, 2 of 20")

        let reviews = element("watch-progress-row-reviews", in: app)
        XCTAssertTrue(reviews.exists)
        XCTAssertEqual(reviews.label, "Reviews due, 1")
    }

    @MainActor
    func testQuickReviewRetriesThenQueuesCorrectAnswer() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-watch-snapshot"]
        app.launch()

        tapButton("watch-quick-review-entry", in: app)
        XCTAssertTrue(
            element("watch-review-prompt", in: app).waitForExistence(timeout: 5)
        )

        tapButton("watch-review-choice-var", in: app)
        tapButton("watch-review-submit", in: app)
        let incorrectFeedback = element("watch-review-feedback", in: app)
        XCTAssertTrue(incorrectFeedback.waitForExistence(timeout: 5))
        XCTAssertEqual(incorrectFeedback.label, "Review again")

        tapButton("watch-review-retry", in: app)
        tapButton("watch-review-choice-let", in: app)
        tapButton("watch-review-submit", in: app)
        let correctFeedback = element("watch-review-feedback", in: app)
        XCTAssertTrue(correctFeedback.waitForExistence(timeout: 5))
        XCTAssertEqual(correctFeedback.label, "Remembered")

        let pending = element("watch-review-pending", in: app)
        XCTAssertTrue(pending.exists)
        XCTAssertEqual(pending.label, "2 changes waiting to sync")

        tapButton("watch-review-finish", in: app)
        XCTAssertTrue(element("watch-home", in: app).waitForExistence(timeout: 5))
    }

    /// Paired-simulator proof. The iPhone app must already be running on the
    /// paired phone with `--ui-testing-persistent --skip-intro
    /// --ui-testing-review-fixture`. Skips when no snapshot arrives, so the
    /// standalone suite stays deterministic.
    @MainActor
    func testPairedPhoneSnapshotReachesWatchAndQueuedAnswerClears() throws {
        let app = XCUIApplication()
        app.launchArguments = []
        app.launch()

        let learnerName = app.staticTexts["watch-learner-name"]
        guard learnerName.waitForExistence(timeout: 60) else {
            throw XCTSkip(
                "No paired iPhone snapshot arrived; run the phone app first."
            )
        }
        XCTAssertEqual(learnerName.label, "Hi, Swift Learner")

        let progress = app.staticTexts["watch-progress-summary"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        XCTAssertTrue(progress.label.hasSuffix("of 486 lessons"))

        let status = app.staticTexts["watch-sync-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertEqual(status.label, "Synced")

        guard app.buttons["watch-quick-review-entry"].waitForExistence(timeout: 10)
        else {
            throw XCTSkip("The paired phone reported no due review item.")
        }

        tapButton("watch-quick-review-entry", in: app)
        XCTAssertTrue(
            element("watch-review-prompt", in: app).waitForExistence(timeout: 10)
        )
        let choice = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'watch-review-choice-'")
        ).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        choice.tap()
        tapButton("watch-review-submit", in: app)
        XCTAssertTrue(
            element("watch-review-feedback", in: app).waitForExistence(timeout: 10)
        )

        // The answer is queued for background transfer. WatchConnectivity
        // decides when `transferUserInfo(_:)` is delivered, so acknowledgement
        // is verified outside XCTest by `Scripts/verify_watch_pair_sync.sh`.
        let pending = element("watch-review-pending", in: app)
        XCTAssertTrue(pending.waitForExistence(timeout: 10))
        XCTAssertTrue(pending.label.hasSuffix("waiting to sync"))
    }

    @MainActor
    private func element(
        _ identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    @MainActor
    private func tapButton(
        _ identifier: String,
        in app: XCUIApplication
    ) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<4 where button.isHittable == false {
            app.swipeUp()
        }
        for _ in 0..<4 where button.isHittable == false {
            app.swipeDown()
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
    }
}
