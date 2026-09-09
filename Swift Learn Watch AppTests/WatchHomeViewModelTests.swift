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
            )
        )

        await viewModel.observe()

        #expect(viewModel.state == .loaded(snapshot))
    }

    @Test
    func observeShowsEmptyStateWithoutSnapshot() async {
        let viewModel = WatchHomeViewModel(
            observeSnapshots: ObserveWatchLearningSnapshotUseCase(
                repository: WatchViewModelRepository(snapshot: nil)
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
