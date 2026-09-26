//
//  ReviewQueueViewModel.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class ReviewQueueViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var items: [ReviewItem] = []
    private(set) var activitySelection = LearningActivitySelection()
    private(set) var attemptResult: LessonAttemptResult?
    private(set) var isSessionComplete = false
    /// Bumped when the question being ordered changes. `load()` runs again on
    /// every journey attempt, so keying on the question is what stops the
    /// answers reordering under the learner mid-review.
    private(set) var choiceOrderRevision = 0
    private var orderedQuestionID: String?

    private let loadReviewQueue: LoadReviewQueueUseCase
    private let completeReview: CompleteReviewUseCase
    private let orderChoices: OrderActivityChoicesUseCase

    var selectedChoiceID: String? { activitySelection.choiceID }
    var selectedFragmentIDs: [String] { activitySelection.orderedFragmentIDs }
    var draftText: String { activitySelection.draftText }
    var selectedTokenIDs: [String] { activitySelection.selectedTokenIDs }

    init(
        loadReviewQueue: LoadReviewQueueUseCase,
        completeReview: CompleteReviewUseCase,
        orderChoices: OrderActivityChoicesUseCase = OrderActivityChoicesUseCase(
            randomizer: IdentityChoiceOrder()
        )
    ) {
        self.loadReviewQueue = loadReviewQueue
        self.completeReview = completeReview
        self.orderChoices = orderChoices
    }

    /// The answers for `item` in display order. Deterministic for a given
    /// lesson and `choiceOrderRevision`, so a redraw never reorders anything.
    func orderedChoices(for item: ReviewItem) -> [LearningChoice] {
        orderChoices.execute(
            item.lesson.activity.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: item.lesson.id,
                attemptNumber: choiceOrderRevision
            )
        )
    }

    func load() {
        loadState = .loading
        do {
            items = try loadReviewQueue.execute()
            activitySelection.reset()
            attemptResult = nil
            isSessionComplete = false
            advanceChoiceOrderIfQuestionChanged()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectChoice(_ choiceID: String) {
        activitySelection.selectChoice(choiceID)
        attemptResult = nil
    }

    func selectFragment(_ id: String) {
        guard let activity = currentItem?.lesson.activity else { return }
        activitySelection.appendFragment(id, for: activity)
        attemptResult = nil
    }

    func removeFragment(_ id: String) {
        activitySelection.removeFragment(id)
        attemptResult = nil
    }

    func editText(_ text: String) {
        activitySelection.editText(text)
        attemptResult = nil
    }

    func selectToken(_ id: String) {
        guard let activity = currentItem?.lesson.activity else { return }
        activitySelection.appendToken(id, for: activity)
        attemptResult = nil
    }

    func removeToken(_ id: String) {
        guard let activity = currentItem?.lesson.activity else { return }
        activitySelection.removeToken(id, for: activity)
        attemptResult = nil
    }

    func resetSelection() {
        activitySelection.reset()
        attemptResult = nil
    }

    private func advanceChoiceOrderIfQuestionChanged() {
        let questionID = items.first?.lesson.id
        guard orderedQuestionID != questionID else { return }
        orderedQuestionID = questionID
        choiceOrderRevision += 1
    }

    var canSubmitCurrentItem: Bool {
        guard let activity = currentItem?.lesson.activity else { return false }
        return activitySelection.response(for: activity) != nil
    }

    func submit(skillID: SkillID) {
        guard let item = currentItem, item.id == skillID,
              let response = activitySelection.response(for: item.lesson.activity) else {
            attemptResult = LessonAttemptResult(
                isCorrect: false,
                feedback: ReviewDomainError.choiceNotFound.localizedDescription
            )
            return
        }

        do {
            let result = try completeReview.execute(
                skillID: skillID,
                response: response
            )
            items = try loadReviewQueue.execute()
            activitySelection.reset()
            attemptResult = result
            isSessionComplete = result.isCorrect && items.isEmpty
            loadState = .loaded
        } catch {
            attemptResult = LessonAttemptResult(
                isCorrect: false,
                feedback: error.localizedDescription
            )
        }
    }

    var currentItem: ReviewItem? {
        items.first
    }

    var summary: String {
        switch items.count {
        case 0:
            "No reviews due"
        case 1:
            "1 review due"
        default:
            "\(items.count) reviews due"
        }
    }
}
