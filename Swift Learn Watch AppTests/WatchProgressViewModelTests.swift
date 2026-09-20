import Foundation
import Testing
@testable import Swift_Learn_Watch_App

@MainActor
struct WatchProgressViewModelTests {
    @Test
    func rowsCombineLevelMasteryAndReviewState() {
        let viewModel = WatchProgressViewModel(
            snapshot: makeSnapshot(detail: makeDetail()),
            pendingSyncEventCount: 2
        )

        #expect(viewModel.hasLevelDetail)
        #expect(viewModel.levelTitle == "Foundations")
        #expect(viewModel.levelProgress == Double(12) / Double(53))
        #expect(viewModel.levelSummary == "12 of 53 lessons in this level")
        #expect(
            viewModel.rows.map(\.id) == [
                "completed",
                "mastered",
                "proficient",
                "reviews",
                "pending"
            ]
        )
        #expect(viewModel.rows.first?.value == "12 of 486")
        #expect(viewModel.rows.last?.value == "2")
    }

    @Test
    func syncedSnapshotHidesPendingRow() {
        let viewModel = WatchProgressViewModel(
            snapshot: makeSnapshot(detail: makeDetail()),
            pendingSyncEventCount: 0
        )

        #expect(viewModel.rows.contains { $0.id == "pending" } == false)
        #expect(
            viewModel.accessibilitySummary
                == "Lessons, 12 of 486. Mastered, 2 of 20. "
                    + "Proficient, 5 of 20. Reviews due, 3"
        )
    }

    @Test
    func snapshotWithoutDetailKeepsLessonAndReviewRowsOnly() {
        let viewModel = WatchProgressViewModel(
            snapshot: makeSnapshot(detail: nil),
            pendingSyncEventCount: 0
        )

        #expect(viewModel.hasLevelDetail == false)
        #expect(viewModel.levelTitle == "Level unavailable")
        #expect(viewModel.levelProgress == 0)
        #expect(viewModel.levelSummary == "Sync with iPhone to see level details")
        #expect(viewModel.rows.map(\.id) == ["completed", "reviews"])
    }

    private func makeDetail() -> WatchProgressDetailSnapshot {
        WatchProgressDetailSnapshot(
            levelTitle: "Foundations",
            levelCompletedLessonCount: 12,
            levelTotalLessonCount: 53,
            trackedSkillCount: 20,
            proficientSkillCount: 5,
            masteredSkillCount: 2
        )
    }

    private func makeSnapshot(
        detail: WatchProgressDetailSnapshot?
    ) -> WatchLearningSnapshot {
        WatchLearningSnapshot(
            learnerName: "Ahmed",
            completedLessonCount: 12,
            totalLessonCount: 486,
            dueReviewCount: 3,
            progressDetail: detail,
            nextLesson: nil,
            generatedAt: Date(timeIntervalSince1970: 2_000_000_000)
        )
    }
}
