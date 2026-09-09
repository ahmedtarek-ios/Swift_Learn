import Foundation

@MainActor
final class InMemoryWatchLearningSnapshotRepository: WatchLearningSnapshotRepository {
    private let result: Result<WatchLearningSnapshot?, any Error>

    init(snapshot: WatchLearningSnapshot?) {
        result = .success(snapshot)
    }

    init(error: any Error) {
        result = .failure(error)
    }

    func snapshots() -> AsyncThrowingStream<WatchLearningSnapshot?, any Error> {
        AsyncThrowingStream { continuation in
            switch result {
            case let .success(snapshot):
                continuation.yield(snapshot)
                continuation.finish()
            case let .failure(error):
                continuation.finish(throwing: error)
            }
        }
    }
}
