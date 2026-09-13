import Foundation
import Testing
@testable import Swift_Learn_Watch_App

@MainActor
struct WatchHomeViewModelTests {
    @Test
    func observeLoadsSnapshot() async {
        let snapshot = makeSnapshot()
        let viewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: WatchViewModelRepository(snapshot: snapshot)
            ),
            loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase(
                repository: WatchSyncViewModelRepository()
            )
        )

        await viewModel.observe()

        #expect(
            viewModel.state == .loaded(
                WatchHomeViewModel.Content(
                    snapshot: snapshot,
                    pendingSyncEventCount: 0
                )
            )
        )
    }

    @Test
    func observeReportsPendingOfflineChanges() async {
        let snapshot = makeSnapshot()
        let event = LearningSyncEvent(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            deviceID: "watch",
            resetGeneration: 0,
            createdAt: Date(timeIntervalSince1970: 2_000_000_000),
            kind: .lessonCompleted,
            lessonID: "lesson.one"
        )
        let viewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: WatchViewModelRepository(snapshot: snapshot)
            ),
            loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase(
                repository: WatchSyncViewModelRepository(pendingEvents: [event])
            )
        )

        await viewModel.observe()

        #expect(
            viewModel.state == .loaded(
                WatchHomeViewModel.Content(
                    snapshot: snapshot,
                    pendingSyncEventCount: 1
                )
            )
        )
    }

    @Test
    func observeShowsEmptyStateWithoutSnapshot() async {
        let viewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: WatchViewModelRepository(snapshot: nil)
            ),
            loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase(
                repository: WatchSyncViewModelRepository()
            )
        )

        await viewModel.observe()

        #expect(viewModel.state == .empty)
    }

    @Test
    func observeExposesRepositoryFailure() async {
        let viewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: WatchFailingViewModelRepository()
            ),
            loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase(
                repository: WatchSyncViewModelRepository()
            )
        )

        await viewModel.observe()

        #expect(viewModel.state == .failed("Snapshot unavailable"))
    }

    private func makeSnapshot() -> WatchLearningSnapshot {
        WatchLearningSnapshot(
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
}

@MainActor
private final class WatchSyncViewModelRepository: LearningSyncRepository {
    private var pendingEvents: [LearningSyncEvent]

    init(pendingEvents: [LearningSyncEvent] = []) {
        self.pendingEvents = pendingEvents
    }

    func loadSnapshot() -> LearningSyncSnapshot { .empty }
    func saveSnapshot(_ snapshot: LearningSyncSnapshot) {}
    func loadPendingEvents() -> [LearningSyncEvent] { pendingEvents }
    func enqueue(_ event: LearningSyncEvent) { pendingEvents.append(event) }
    func removePendingEvents(ids: Set<UUID>) {
        pendingEvents.removeAll { ids.contains($0.id) }
    }
}

@MainActor
private struct WatchViewModelRepository: WatchLearningSnapshotRepository {
    let snapshot: WatchLearningSnapshot?

    func snapshots() -> AsyncThrowingStream<WatchLearningSnapshot?, any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(snapshot)
            continuation.finish()
        }
    }
}

@MainActor
private struct WatchFailingViewModelRepository: WatchLearningSnapshotRepository {
    func snapshots() -> AsyncThrowingStream<WatchLearningSnapshot?, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: WatchViewModelFixtureError.unavailable)
        }
    }
}

private enum WatchViewModelFixtureError: LocalizedError {
    case unavailable

    var errorDescription: String? { "Snapshot unavailable" }
}
