//
//  MistakeNotebookViewModel.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class MistakeNotebookViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var entries: [MistakeNotebookEntry] = []

    private let loadMistakes: LoadMistakeNotebookUseCase

    init(loadMistakes: LoadMistakeNotebookUseCase) {
        self.loadMistakes = loadMistakes
    }

    func load() {
        loadState = .loading
        do {
            entries = try loadMistakes.execute()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
