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

    private let loadReviewQueue: LoadReviewQueueUseCase
    private let completeReview: CompleteReviewUseCase

    var selectedChoiceID: String? { activitySelection.choiceID }
    var selectedFragmentIDs: [String] { activitySelection.orderedFragmentIDs }
    var draftText: String { activitySelection.draftText }
    var selectedTokenIDs: [String] { activitySelection.selectedTokenIDs }

    init(
        loadReviewQueue: LoadReviewQueueUseCase,
        completeReview: CompleteReviewUseCase
    ) {
        self.loadReviewQueue = loadReviewQueue
        self.completeReview = completeReview
    }

    func load() {
        loadState = .loading
        do {
            items = try loadReviewQueue.execute()
            activitySelection.reset()
            attemptResult = nil
            isSessionComplete = false
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
