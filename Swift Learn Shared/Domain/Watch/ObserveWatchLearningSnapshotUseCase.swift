import Foundation

@MainActor
struct ObserveWatchLearningSnapshotUseCase {
    private let repository: any WatchLearningSnapshotRepository

    init(repository: any WatchLearningSnapshotRepository) {
        self.repository = repository
    }

    func execute() -> AsyncThrowingStream<WatchLearningSnapshot?, any Error> {
        repository.snapshots()
    }
}
