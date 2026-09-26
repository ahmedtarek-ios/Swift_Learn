import Foundation
import Observation

@MainActor
@Observable
final class GitLearningViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(GitLearningTrack)
        case empty
        case failed(String)
    }

    enum ResetState: Equatable {
        case idle
        case confirming
        case resetting
        case succeeded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var resetState: ResetState = .idle
    private(set) var currentLesson: GitCommandLesson?
    private(set) var selectedChoiceID: String?
    private(set) var answerResult: GitAnswerResult?
    private(set) var recentlyUnlockedLessonID: String?
    private(set) var navigationRevision = 0
    /// Bumped when the question being ordered changes, so re-opening the same
    /// question never reorders the commands mid-attempt.
    private(set) var choiceOrderRevision = 0
    private var orderedQuestionID: String?

    private let loadTrack: LoadGitLearningTrackUseCase
    private let submitAnswer: SubmitGitAnswerUseCase
    private let resetProgress: ResetGitTrackProgressUseCase
    private let orderChoices: OrderActivityChoicesUseCase

    init(
        loadTrack: LoadGitLearningTrackUseCase,
        submitAnswer: SubmitGitAnswerUseCase,
        resetProgress: ResetGitTrackProgressUseCase,
        orderChoices: OrderActivityChoicesUseCase = OrderActivityChoicesUseCase(
            randomizer: IdentityChoiceOrder()
        )
    ) {
        self.loadTrack = loadTrack
        self.submitAnswer = submitAnswer
        self.resetProgress = resetProgress
        self.orderChoices = orderChoices
    }

    /// The commands for `lesson` in display order. Deterministic for a given
    /// lesson and `choiceOrderRevision`, so a redraw never reorders anything.
    func orderedChoices(for lesson: GitCommandLesson) -> [GitCommandChoice] {
        orderChoices.execute(
            lesson.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: lesson.id,
                attemptNumber: choiceOrderRevision
            )
        )
    }

    var track: GitLearningTrack? {
        guard case let .loaded(track) = loadState else { return nil }
        return track
    }

    var progressSummary: String {
        guard let track else { return "No Git questions yet" }
        return "\(track.completedLessonCount) of \(track.totalLessonCount) commands"
    }

    var isTrackComplete: Bool { track?.isTrackComplete ?? false }

    var canSubmit: Bool {
        selectedChoiceID != nil && answerResult == nil && currentLesson != nil
    }

    var nextLesson: GitCommandLesson? {
        guard let track, let currentLesson else { return nil }
        return track.lesson(after: currentLesson.id)
    }

    func load() {
        loadState = .loading
        recentlyUnlockedLessonID = nil
        do {
            let track = try loadTrack.execute()
            guard track.totalLessonCount > 0 else {
                loadState = .empty
                return
            }
            loadState = .loaded(track)
            if currentLesson == nil || track.isCompleted(lessonID: currentLesson?.id ?? "") {
                currentLesson = track.resumeLesson
            }
            selectedChoiceID = nil
            answerResult = nil
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func open(lessonID: String) {
        guard let track, track.isUnlocked(lessonID: lessonID),
              let lesson = track.catalog.lesson(id: lessonID) else { return }
        if orderedQuestionID != lessonID {
            orderedQuestionID = lessonID
            choiceOrderRevision += 1
        }
        currentLesson = lesson
        selectedChoiceID = nil
        answerResult = nil
    }

    /// Called from the challenge view's `onAppear`, which SwiftUI fires again
    /// for the question already on screen. Opening it again would clear the
    /// learner's selected command and any feedback, so only a change of
    /// question starts a new attempt.
    func beginLesson(id lessonID: String) {
        guard currentLesson?.id != lessonID else { return }
        open(lessonID: lessonID)
    }

    func select(choiceID: String) {
        guard answerResult == nil else { return }
        selectedChoiceID = choiceID
    }

    func submit() {
        guard let lesson = currentLesson, let choiceID = selectedChoiceID else { return }
        submit(lessonID: lesson.id, choiceID: choiceID)
    }

    func canSubmit(lessonID: String) -> Bool {
        currentLesson?.id == lessonID && canSubmit
    }

    func submit(lessonID: String) {
        guard currentLesson?.id == lessonID, let choiceID = selectedChoiceID else { return }
        submit(lessonID: lessonID, choiceID: choiceID)
    }

    func nextLesson(after lessonID: String) -> GitCommandLesson? {
        track?.lesson(after: lessonID)
    }

    func finishTrack() {
        currentLesson = nil
        selectedChoiceID = nil
        answerResult = nil
        recentlyUnlockedLessonID = nil
        navigationRevision += 1
    }

    private func submit(lessonID: String, choiceID: String) {
        do {
            let result = try submitAnswer.execute(
                lessonID: lessonID,
                choiceID: choiceID
            )
            if result.didComplete {
                reloadTrackKeepingLesson()
                recentlyUnlockedLessonID = track?.lesson(after: lessonID)?.id
            }
            answerResult = result
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func retryCurrentQuestion() {
        selectedChoiceID = nil
        answerResult = nil
    }

    func continueToNextQuestion() {
        guard let next = nextLesson else {
            currentLesson = nil
            return
        }
        currentLesson = next
        selectedChoiceID = nil
        answerResult = nil
    }

    // MARK: - Reset

    func requestReset() {
        resetState = .confirming
    }

    func cancelReset() {
        resetState = .idle
    }

    func confirmReset() {
        resetState = .resetting
        do {
            try resetProgress.execute()
            currentLesson = nil
            selectedChoiceID = nil
            answerResult = nil
            recentlyUnlockedLessonID = nil
            load()
            resetState = .succeeded
            navigationRevision += 1
        } catch {
            resetState = .failed(error.localizedDescription)
        }
    }

    func acknowledgeResetOutcome() {
        resetState = .idle
    }

    private func reloadTrackKeepingLesson() {
        do {
            let refreshed = try loadTrack.execute()
            loadState = .loaded(refreshed)
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
