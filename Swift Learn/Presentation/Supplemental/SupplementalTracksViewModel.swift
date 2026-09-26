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
    private(set) var labSelectionByLessonID: [String: LearningActivitySelection] = [:]
    private(set) var labResultByLessonID: [String: SupplementalPracticeResult] = [:]
    /// Bumped only by the explicit Reset control. Loading the tracks must not
    /// advance it: the discovery screen reloads while practices are on screen.
    private(set) var choiceOrderRevision = 0
    private let loadTracks: LoadSupplementalTracksUseCase
    private let evaluatePractice: EvaluateSupplementalPracticeUseCase
    private let evaluateLab: EvaluateSupplementalAuthoredLabUseCase
    private let orderChoices: OrderActivityChoicesUseCase

    init(
        loadTracks: LoadSupplementalTracksUseCase,
        evaluatePractice: EvaluateSupplementalPracticeUseCase,
        evaluateLab: EvaluateSupplementalAuthoredLabUseCase,
        orderChoices: OrderActivityChoicesUseCase = OrderActivityChoicesUseCase(
            randomizer: IdentityChoiceOrder()
        )
    ) {
        self.loadTracks = loadTracks
        self.evaluatePractice = evaluatePractice
        self.evaluateLab = evaluateLab
        self.orderChoices = orderChoices
    }

    /// Practice answers for `lesson` in display order. Deterministic for a given
    /// lesson and `choiceOrderRevision`, so a redraw never reorders anything.
    func orderedPracticeChoices(
        for lesson: SupplementalLesson
    ) -> [SupplementalPracticeChoice] {
        orderChoices.execute(
            lesson.practice.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: lesson.id,
                attemptNumber: choiceOrderRevision
            )
        )
    }

    func orderedLabChoices(for lesson: SupplementalLesson) -> [LearningChoice] {
        guard let activity = lesson.lab?.activity else { return [] }
        return orderChoices.execute(
            activity.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: "\(lesson.id)#lab",
                attemptNumber: choiceOrderRevision
            )
        )
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
        choiceOrderRevision += 1
        selectedChoiceByLessonID[lessonID] = nil
        resultByLessonID[lessonID] = nil
        labSelectionByLessonID[lessonID] = nil
        labResultByLessonID[lessonID] = nil
    }

    func labSelection(for lessonID: String) -> LearningActivitySelection {
        labSelectionByLessonID[lessonID] ?? LearningActivitySelection()
    }

    func editLabText(_ text: String, for lessonID: String) {
        var selection = labSelection(for: lessonID)
        selection.editText(text)
        labSelectionByLessonID[lessonID] = selection
        labResultByLessonID[lessonID] = nil
    }

    func selectLabToken(_ id: String, for lesson: SupplementalLesson) {
        guard let activity = lesson.lab?.activity else { return }
        var selection = labSelection(for: lesson.id)
        selection.appendToken(id, for: activity)
        labSelectionByLessonID[lesson.id] = selection
        labResultByLessonID[lesson.id] = nil
    }

    func removeLabToken(_ id: String, for lesson: SupplementalLesson) {
        guard let activity = lesson.lab?.activity else { return }
        var selection = labSelection(for: lesson.id)
        selection.removeToken(id, for: activity)
        labSelectionByLessonID[lesson.id] = selection
        labResultByLessonID[lesson.id] = nil
    }

    func resetLabSelection(for lessonID: String) {
        labSelectionByLessonID[lessonID] = nil
        labResultByLessonID[lessonID] = nil
    }

    func classify(
        itemID: String,
        as layer: ArchitectureLayer,
        for lesson: SupplementalLesson
    ) {
        guard let activity = lesson.lab?.activity else { return }
        var selection = labSelection(for: lesson.id)
        selection.selectLayer(layer, itemID: itemID, for: activity)
        labSelectionByLessonID[lesson.id] = selection
        labResultByLessonID[lesson.id] = nil
    }

    func canSubmitLab(_ lesson: SupplementalLesson) -> Bool {
        guard let activity = lesson.lab?.activity else { return false }
        return labSelection(for: lesson.id).response(for: activity) != nil
    }

    func submitLab(_ lesson: SupplementalLesson) {
        guard let activity = lesson.lab?.activity,
              let response = labSelection(for: lesson.id).response(for: activity) else {
            return
        }
        do {
            labResultByLessonID[lesson.id] = try evaluateLab.execute(
                response: response,
                lesson: lesson
            )
        } catch {
            labResultByLessonID[lesson.id] = .incorrect(error.localizedDescription)
        }
    }
}
