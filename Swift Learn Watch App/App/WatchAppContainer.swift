import Foundation

@MainActor
final class WatchAppContainer {
    let homeViewModel: WatchHomeViewModel

    init(processInfo: ProcessInfo = .processInfo) {
        let repository: any WatchLearningSnapshotRepository
        let syncRepository: any LearningSyncEventQueueRepository
        if processInfo.arguments.contains("--ui-testing-watch-snapshot") {
            repository = InMemoryWatchLearningSnapshotRepository(
                snapshot: Self.uiTestSnapshot
            )
            syncRepository = InMemoryLearningSyncRepository(
                pendingEvents: processInfo.arguments.contains(
                    "--ui-testing-watch-pending-sync"
                ) ? [Self.uiTestPendingEvent] : []
            )
        } else if processInfo.arguments.contains("--ui-testing-watch-empty") {
            repository = InMemoryWatchLearningSnapshotRepository(snapshot: nil)
            syncRepository = InMemoryLearningSyncRepository()
        } else {
            let localSyncRepository = UserDefaultsLearningSyncRepository()
            repository = WatchConnectivityLearningSnapshotRepository(
                syncEventQueue: localSyncRepository,
                syncGeneration: localSyncRepository
            )
            syncRepository = localSyncRepository
        }

        homeViewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: repository
            ),
            loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase(
                repository: syncRepository
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

    private static let uiTestPendingEvent = LearningSyncEvent(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        deviceID: "watch-ui-test",
        resetGeneration: 0,
        createdAt: Date(timeIntervalSince1970: 2_000_000_000),
        kind: .lessonCompleted,
        lessonID: "swift.bindings.constants"
    )
}
