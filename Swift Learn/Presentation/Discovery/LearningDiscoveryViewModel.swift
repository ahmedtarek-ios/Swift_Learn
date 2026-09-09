import Foundation
import Observation

@Observable
@MainActor
final class LearningDiscoveryViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var snapshot: LearningDiscoverySnapshot?
    private(set) var searchResults: [LearningDiscoveryResult] = []
    var query = "" {
        didSet { updateSearchResults() }
    }

    private let loadDiscovery: LoadLearningDiscoveryUseCase
    private let searchDiscovery: SearchLearningDiscoveryUseCase

    init(
        loadDiscovery: LoadLearningDiscoveryUseCase,
        searchDiscovery: SearchLearningDiscoveryUseCase
    ) {
        self.loadDiscovery = loadDiscovery
        self.searchDiscovery = searchDiscovery
    }

    func load() {
        loadState = .loading
        do {
            snapshot = try loadDiscovery.execute()
            updateSearchResults()
            loadState = .loaded
        } catch {
            snapshot = nil
            searchResults = []
            loadState = .failed(error.localizedDescription)
        }
    }

    private func updateSearchResults() {
        guard let snapshot else {
            searchResults = []
            return
        }
        searchResults = searchDiscovery.execute(query: query, snapshot: snapshot)
    }
}
