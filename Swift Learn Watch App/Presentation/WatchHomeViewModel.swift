import Foundation
import Combine

@MainActor
final class WatchHomeViewModel: ObservableObject {
    struct Content: Equatable {
        let snapshot: WatchLearningSnapshot
        let pendingSyncEventCount: Int
    }

    enum State: Equatable {
        case idle
        case loading
        case empty
        case loaded(Content)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private let observeSnapshots: ObserveWatchLearningSnapshotUseCase
    private let loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase

    init(
        observeSnapshots: ObserveWatchLearningSnapshotUseCase,
        loadPendingSyncEvents: LoadPendingLearningSyncEventsUseCase
    ) {
        self.observeSnapshots = observeSnapshots
        self.loadPendingSyncEvents = loadPendingSyncEvents
    }

    func observe() async {
        state = .loading
        do {
            for try await snapshot in observeSnapshots.execute() {
                guard !Task.isCancelled else { return }
                guard let snapshot else {
                    state = .empty
                    continue
                }
                state = .loaded(
                    Content(
                        snapshot: snapshot,
                        pendingSyncEventCount: try loadPendingSyncEvents.execute().count
                    )
                )
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
