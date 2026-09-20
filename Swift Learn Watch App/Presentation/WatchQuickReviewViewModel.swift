import Foundation
import Observation

@Observable
@MainActor
final class WatchQuickReviewViewModel {
    struct Feedback: Equatable {
        let isCorrect: Bool
        let message: String
        let isSessionComplete: Bool
    }

    enum Phase: Equatable {
        case idle
        case reviewing
        case feedback(Feedback)
        case empty
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var selectedChoiceID: String?
    private(set) var pendingSyncEventCount = 0
    private(set) var successHapticSequence = 0
    private(set) var errorHapticSequence = 0
    private(set) var items: [WatchReviewItemSnapshot] = []

    private let submitAnswer: SubmitWatchQuickReviewAnswerUseCase
    private let loadPendingEvents: LoadPendingLearningSyncEventsUseCase

    init(
        submitAnswer: SubmitWatchQuickReviewAnswerUseCase,
        loadPendingEvents: LoadPendingLearningSyncEventsUseCase
    ) {
        self.submitAnswer = submitAnswer
        self.loadPendingEvents = loadPendingEvents
    }

    var currentItem: WatchReviewItemSnapshot? { items.first }

    var canSubmit: Bool {
        phase == .reviewing && selectedChoiceID != nil
    }

    func start(
        items: [WatchReviewItemSnapshot],
        resetGeneration: Int
    ) {
        do {
            let pendingEvents = try loadPendingEvents.execute()
            let completedSkillIDs = Set(
                pendingEvents.compactMap { event -> String? in
                    guard event.resetGeneration == resetGeneration,
                          event.kind == .attemptRecorded,
                          event.attempt?.outcome == .correct,
                          let attempt = event.attempt,
                          attempt.activityID == "review.\(attempt.skillID)" else {
                        return nil
                    }
                    return attempt.skillID
                }
            )
            self.items = items.filter {
                completedSkillIDs.contains($0.skillID) == false
            }
            pendingSyncEventCount = pendingEvents.count
            selectedChoiceID = nil
            phase = self.items.isEmpty ? .empty : .reviewing
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func selectChoice(_ choiceID: String) {
        guard phase == .reviewing,
              currentItem?.choices.contains(where: { $0.id == choiceID }) == true else {
            return
        }
        selectedChoiceID = choiceID
    }

    func submit() {
        guard phase == .reviewing,
              let item = currentItem,
              let selectedChoiceID else { return }

        do {
            let submission = try submitAnswer.execute(
                item: item,
                choiceID: selectedChoiceID
            )
            pendingSyncEventCount = try loadPendingEvents.execute().count
            if submission.isCorrect {
                items.removeFirst()
                successHapticSequence += 1
            } else {
                errorHapticSequence += 1
            }
            phase = .feedback(
                Feedback(
                    isCorrect: submission.isCorrect,
                    message: submission.feedback,
                    isSessionComplete: submission.isCorrect && items.isEmpty
                )
            )
        } catch {
            phase = .failed(error.localizedDescription)
            errorHapticSequence += 1
        }
    }

    func retry() {
        guard case let .feedback(feedback) = phase,
              feedback.isCorrect == false else { return }
        selectedChoiceID = nil
        phase = .reviewing
    }

    func continueToNextReview() {
        guard case let .feedback(feedback) = phase,
              feedback.isCorrect,
              feedback.isSessionComplete == false,
              items.isEmpty == false else { return }
        selectedChoiceID = nil
        phase = .reviewing
    }

    func retryAfterFailure() {
        guard case .failed = phase, currentItem != nil else { return }
        selectedChoiceID = nil
        phase = .reviewing
    }
}
