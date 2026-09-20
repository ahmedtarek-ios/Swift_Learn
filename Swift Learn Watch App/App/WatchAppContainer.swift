import Foundation

@MainActor
final class WatchAppContainer {
    let homeViewModel: WatchHomeViewModel
    let quickReviewViewModel: WatchQuickReviewViewModel

    init(processInfo: ProcessInfo = .processInfo) {
        let repository: any WatchLearningSnapshotRepository
        let syncRepository: any LearningSyncRepository
        let eventSubmitter: any WatchLearningEventSubmitting
        if processInfo.arguments.contains("--ui-testing-watch-snapshot") {
            let inMemorySyncRepository = InMemoryLearningSyncRepository(
                pendingEvents: processInfo.arguments.contains(
                    "--ui-testing-watch-pending-sync"
                ) ? [Self.uiTestPendingEvent] : []
            )
            repository = InMemoryWatchLearningSnapshotRepository(
                snapshot: Self.uiTestSnapshot
            )
            syncRepository = inMemorySyncRepository
            eventSubmitter = inMemorySyncRepository
        } else if processInfo.arguments.contains("--ui-testing-watch-empty") {
            let inMemorySyncRepository = InMemoryLearningSyncRepository()
            repository = InMemoryWatchLearningSnapshotRepository(snapshot: nil)
            syncRepository = inMemorySyncRepository
            eventSubmitter = inMemorySyncRepository
        } else if processInfo.arguments.contains("--ui-testing-watch-error") {
            let inMemorySyncRepository = InMemoryLearningSyncRepository()
            repository = InMemoryWatchLearningSnapshotRepository(
                error: WatchUITestFixtureError.snapshotUnavailable
            )
            syncRepository = inMemorySyncRepository
            eventSubmitter = inMemorySyncRepository
        } else {
            let localSyncRepository = UserDefaultsLearningSyncRepository()
            let connectivityRepository = WatchConnectivityLearningSnapshotRepository(
                syncEventQueue: localSyncRepository,
                syncGeneration: localSyncRepository
            )
            repository = connectivityRepository
            syncRepository = localSyncRepository
            eventSubmitter = connectivityRepository
        }

        let loadPendingEvents = LoadPendingLearningSyncEventsUseCase(
            repository: syncRepository
        )
        homeViewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: repository
            ),
            loadPendingSyncEvents: loadPendingEvents
        )
        quickReviewViewModel = WatchQuickReviewViewModel(
            submitAnswer: SubmitWatchQuickReviewAnswerUseCase(
                submitEvent: eventSubmitter,
                loadSyncSnapshot: LoadLearningSyncSnapshotUseCase(
                    repository: syncRepository
                ),
                clock: SystemWatchQuickReviewClock(),
                idGenerator: SystemWatchQuickReviewIDGenerator(),
                deviceIDProvider: UserDefaultsWatchDeviceIDProvider()
            ),
            loadPendingEvents: loadPendingEvents
        )
    }

    private static let uiTestSnapshot = WatchLearningSnapshot(
        learnerName: "Ahmed",
        completedLessonCount: 12,
        totalLessonCount: 486,
        dueReviewCount: 1,
        reviewItems: [
            WatchReviewItemSnapshot(
                skillID: "swift.bindings.constants",
                lessonID: "swift.bindings.constants",
                activityID: "review.swift.bindings.constants",
                title: "Constants and Variables",
                prompt: "Which declaration creates a constant?",
                choices: [
                    WatchReviewChoiceSnapshot(id: "var", text: "var"),
                    WatchReviewChoiceSnapshot(id: "let", text: "let")
                ],
                correctChoiceID: "let",
                correctFeedback: "Correct — let creates a constant.",
                incorrectFeedback: "Try again — var creates a variable."
            )
        ],
        progressDetail: WatchProgressDetailSnapshot(
            levelTitle: "Level 1 · Values & Expressions",
            levelCompletedLessonCount: 12,
            levelTotalLessonCount: 53,
            trackedSkillCount: 20,
            proficientSkillCount: 5,
            masteredSkillCount: 2
        ),
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

private enum WatchUITestFixtureError: LocalizedError {
    case snapshotUnavailable

    var errorDescription: String? { "Snapshot unavailable" }
}
