import Foundation

@MainActor
final class WatchAppContainer {
    let homeViewModel: WatchHomeViewModel

    init(processInfo: ProcessInfo = .processInfo) {
        let repository: any WatchLearningSnapshotRepository
        if processInfo.arguments.contains("--ui-testing-watch-snapshot") {
            repository = InMemoryWatchLearningSnapshotRepository(
                snapshot: Self.uiTestSnapshot
            )
        } else if processInfo.arguments.contains("--ui-testing-watch-empty") {
            repository = InMemoryWatchLearningSnapshotRepository(snapshot: nil)
        } else {
            repository = WatchConnectivityLearningSnapshotRepository()
        }

        homeViewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: repository
            )
        )
    }

    private static let uiTestSnapshot = WatchLearningSnapshot(
        learnerName: "Ahmed",
        completedLessonCount: 12,
        totalLessonCount: 486,
        dueReviewCount: 2,
        nextLesson: WatchNextLessonSnapshot(
            id: "swift.bindings.constants",
            title: "Constants and Variables",
            objective: "Choose the Swift declaration that creates a constant."
        ),
        generatedAt: Date(timeIntervalSince1970: 2_000_000_000)
    )
}
