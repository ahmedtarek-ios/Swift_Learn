import Foundation
import Combine

@MainActor
final class WatchHomeViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case loaded(WatchLearningSnapshot)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private let observeSnapshots: ObserveWatchLearningSnapshotUseCase

    init(observeSnapshots: ObserveWatchLearningSnapshotUseCase) {
        self.observeSnapshots = observeSnapshots
    }

    func observe() async {
        state = .loading
        do {
            for try await snapshot in observeSnapshots.execute() {
                guard !Task.isCancelled else { return }
                state = snapshot.map(State.loaded) ?? .empty
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
