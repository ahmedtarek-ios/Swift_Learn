import Foundation
import Observation

@Observable
@MainActor
final class SupplementalTracksViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var tracks: [SupplementalTrack] = []
    private(set) var selectedChoiceByLessonID: [String: String] = [:]
    private(set) var resultByLessonID: [String: SupplementalPracticeResult] = [:]
    private let loadTracks: LoadSupplementalTracksUseCase
    private let evaluatePractice: EvaluateSupplementalPracticeUseCase

    init(
        loadTracks: LoadSupplementalTracksUseCase,
        evaluatePractice: EvaluateSupplementalPracticeUseCase
    ) {
        self.loadTracks = loadTracks
        self.evaluatePractice = evaluatePractice
    }

    func load() {
        loadState = .loading
        do {
            tracks = try loadTracks.execute()
            loadState = .loaded
        } catch {
            tracks = []
            loadState = .failed(error.localizedDescription)
        }
    }

    func select(choiceID: String, for lessonID: String) {
        selectedChoiceByLessonID[lessonID] = choiceID
        resultByLessonID[lessonID] = nil
    }

    func submit(_ lesson: SupplementalLesson) {
        guard let choiceID = selectedChoiceByLessonID[lesson.id] else { return }
        resultByLessonID[lesson.id] = evaluatePractice.execute(
            choiceID: choiceID,
            lesson: lesson
        )
    }

    func resetPractice(for lessonID: String) {
        selectedChoiceByLessonID[lessonID] = nil
        resultByLessonID[lessonID] = nil
    }
}
