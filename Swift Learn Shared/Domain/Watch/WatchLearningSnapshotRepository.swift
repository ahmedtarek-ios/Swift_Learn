import Foundation

@MainActor
protocol WatchLearningSnapshotRepository {
    func snapshots() -> AsyncThrowingStream<WatchLearningSnapshot?, any Error>
}

@MainActor
protocol WatchLearningSnapshotPublishing {
    func activate()
    func publish(_ snapshot: WatchLearningSnapshot) throws
}
