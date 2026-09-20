import Foundation

/// Display state for the Watch complication and Smart Stack widget. It maps an
/// already synchronized snapshot and never evaluates answers or loads content.
nonisolated struct WatchWidgetPresentation: Equatable {
    static let deepLinkURL = URL(string: "swiftlearn://watch/home")!

    let progress: Double
    let progressText: String
    let headline: String
    let detail: String
    let dueReviewCount: Int
    let isPlaceholder: Bool

    init(snapshot: WatchLearningSnapshot?) {
        guard let snapshot else {
            progress = 0
            progressText = "—"
            headline = "Open Swift Learn"
            detail = "Sync with iPhone to see progress"
            dueReviewCount = 0
            isPlaceholder = true
            return
        }

        progress = snapshot.progress
        progressText = "\(Int((snapshot.progress * 100).rounded()))%"
        dueReviewCount = snapshot.dueReviewCount
        isPlaceholder = false

        switch snapshot.dueReviewCount {
        case 0:
            headline = snapshot.nextLesson?.title ?? "Journey complete"
            detail = "\(snapshot.completedLessonCount) of "
                + "\(snapshot.totalLessonCount) lessons"
        case 1:
            headline = "1 review due"
            detail = snapshot.reviewItems.first?.title
                ?? snapshot.nextLesson?.title
                ?? "Open Quick Review"
        default:
            headline = "\(snapshot.dueReviewCount) reviews due"
            detail = "\(snapshot.completedLessonCount) of "
                + "\(snapshot.totalLessonCount) lessons"
        }
    }

    var accessibilityLabel: String {
        isPlaceholder
            ? "Swift Learn. \(detail)"
            : "Swift Learn, \(progressText) complete. \(headline)"
    }

    var inlineText: String {
        isPlaceholder ? "Swift Learn" : "\(progressText) · \(headline)"
    }
}
