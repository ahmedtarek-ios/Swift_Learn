import Foundation

/// Presentation state for the Watch Progress screen. It formats an already
/// synchronized snapshot and never loads or evaluates learning itself.
@MainActor
struct WatchProgressViewModel: Equatable {
    struct Row: Equatable, Identifiable {
        let id: String
        let title: String
        let value: String
    }

    private let snapshot: WatchLearningSnapshot
    private let pendingSyncEventCount: Int

    init(snapshot: WatchLearningSnapshot, pendingSyncEventCount: Int) {
        self.snapshot = snapshot
        self.pendingSyncEventCount = pendingSyncEventCount
    }

    var levelTitle: String {
        snapshot.progressDetail?.levelTitle ?? "Level unavailable"
    }

    var levelProgress: Double {
        snapshot.progressDetail?.levelProgress ?? 0
    }

    var hasLevelDetail: Bool { snapshot.progressDetail != nil }

    var levelSummary: String {
        guard let detail = snapshot.progressDetail else {
            return "Sync with iPhone to see level details"
        }
        return "\(detail.levelCompletedLessonCount) of "
            + "\(detail.levelTotalLessonCount) lessons in this level"
    }

    var rows: [Row] {
        var rows = [
            Row(
                id: "completed",
                title: "Lessons",
                value: "\(snapshot.completedLessonCount) of \(snapshot.totalLessonCount)"
            )
        ]
        if let detail = snapshot.progressDetail {
            rows.append(
                Row(
                    id: "mastered",
                    title: "Mastered",
                    value: "\(detail.masteredSkillCount) of \(detail.trackedSkillCount)"
                )
            )
            rows.append(
                Row(
                    id: "proficient",
                    title: "Proficient",
                    value: "\(detail.proficientSkillCount) of \(detail.trackedSkillCount)"
                )
            )
        }
        rows.append(
            Row(
                id: "reviews",
                title: "Reviews due",
                value: "\(snapshot.dueReviewCount)"
            )
        )
        if pendingSyncEventCount > 0 {
            rows.append(
                Row(
                    id: "pending",
                    title: "Waiting to sync",
                    value: "\(pendingSyncEventCount)"
                )
            )
        }
        return rows
    }

    var accessibilitySummary: String {
        rows.map { "\($0.title), \($0.value)" }.joined(separator: ". ")
    }
}
