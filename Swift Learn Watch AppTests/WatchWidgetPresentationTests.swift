import Foundation
import Testing
@testable import Swift_Learn_Watch_App

struct WatchWidgetPresentationTests {
    @Test
    func missingSnapshotShowsPlaceholderGuidance() {
        let presentation = WatchWidgetPresentation(snapshot: nil)

        #expect(presentation.isPlaceholder)
        #expect(presentation.progress == 0)
        #expect(presentation.progressText == "—")
        #expect(presentation.headline == "Open Swift Learn")
        #expect(presentation.detail == "Sync with iPhone to see progress")
        #expect(presentation.inlineText == "Swift Learn")
        #expect(
            presentation.accessibilityLabel
                == "Swift Learn. Sync with iPhone to see progress"
        )
    }

    @Test
    func dueReviewsLeadTheComplication() {
        let presentation = WatchWidgetPresentation(
            snapshot: makeSnapshot(dueReviewCount: 3)
        )

        #expect(presentation.isPlaceholder == false)
        #expect(presentation.headline == "3 reviews due")
        #expect(presentation.detail == "243 of 486 lessons")
        #expect(presentation.progressText == "50%")
        #expect(presentation.dueReviewCount == 3)
        #expect(presentation.inlineText == "50% · 3 reviews due")
        #expect(
            presentation.accessibilityLabel
                == "Swift Learn, 50% complete. 3 reviews due"
        )
    }

    @Test
    func singleReviewNamesTheSkill() {
        let presentation = WatchWidgetPresentation(
            snapshot: makeSnapshot(dueReviewCount: 1, includesReviewItem: true)
        )

        #expect(presentation.headline == "1 review due")
        #expect(presentation.detail == "Constants and Variables")
    }

    @Test
    func withoutReviewsTheNextLessonLeads() {
        let presentation = WatchWidgetPresentation(
            snapshot: makeSnapshot(dueReviewCount: 0)
        )

        #expect(presentation.headline == "Optionals")
        #expect(presentation.detail == "243 of 486 lessons")
    }

    @Test
    func sharedStoreReadsAndRejectsUnusableData() throws {
        let defaults = try #require(
            UserDefaults(suiteName: "WatchWidgetPresentationTests")
        )
        defer { defaults.removePersistentDomain(forName: "WatchWidgetPresentationTests") }

        #expect(WatchSharedStore.loadSnapshot(from: defaults) == nil)

        defaults.set(Data("not a snapshot".utf8), forKey: WatchSharedStore.snapshotCacheKey)
        #expect(WatchSharedStore.loadSnapshot(from: defaults) == nil)

        let snapshot = makeSnapshot(dueReviewCount: 2)
        defaults.set(
            try WatchLearningSnapshotWireFormat.encode(snapshot),
            forKey: WatchSharedStore.snapshotCacheKey
        )
        #expect(WatchSharedStore.loadSnapshot(from: defaults) == snapshot)
    }

    private func makeSnapshot(
        dueReviewCount: Int,
        includesReviewItem: Bool = false
    ) -> WatchLearningSnapshot {
        WatchLearningSnapshot(
            learnerName: "Ahmed",
            completedLessonCount: 243,
            totalLessonCount: 486,
            dueReviewCount: dueReviewCount,
            reviewItems: includesReviewItem
                ? [
                    WatchReviewItemSnapshot(
                        skillID: "swift.bindings.constants",
                        lessonID: "swift.bindings.constants",
                        activityID: "review.swift.bindings.constants",
                        title: "Constants and Variables",
                        prompt: "Which declaration creates a constant?",
                        choices: [
                            WatchReviewChoiceSnapshot(id: "let", text: "let")
                        ],
                        correctChoiceID: "let",
                        correctFeedback: "Correct",
                        incorrectFeedback: "Review again"
                    )
                ]
                : [],
            nextLesson: WatchNextLessonSnapshot(
                id: "swift.optionals",
                title: "Optionals",
                objective: "Handle a missing value."
            ),
            generatedAt: Date(timeIntervalSince1970: 2_000_000_000)
        )
    }
}
