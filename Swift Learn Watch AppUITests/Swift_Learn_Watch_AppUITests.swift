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

        XCTAssertTrue(app.otherElements["watch-home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["watch-learner-name"].exists)
        XCTAssertTrue(app.staticTexts["watch-progress-summary"].exists)
        XCTAssertTrue(app.staticTexts["watch-review-count"].exists)
        XCTAssertTrue(app.staticTexts["watch-sync-status"].exists)

        let nextLesson = app.buttons["watch-next-lesson"]
        XCTAssertTrue(nextLesson.exists)
        nextLesson.tap()

        XCTAssertTrue(
            app.otherElements["watch-next-lesson-detail"].waitForExistence(timeout: 5)
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

        XCTAssertTrue(
            app.otherElements["watch-empty-state"].waitForExistence(timeout: 5)
        )
    }
}
