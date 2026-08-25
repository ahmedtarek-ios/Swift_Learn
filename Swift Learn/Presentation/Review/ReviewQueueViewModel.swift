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
    private(set) var selectedChoiceID: String?
    private(set) var attemptResult: LessonAttemptResult?
    private(set) var isSessionComplete = false

    private let loadReviewQueue: LoadReviewQueueUseCase
    private let completeReview: CompleteReviewUseCase

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
            selectedChoiceID = nil
            attemptResult = nil
            isSessionComplete = false
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectChoice(_ choiceID: String) {
        selectedChoiceID = choiceID
        attemptResult = nil
    }

    func submit(skillID: SkillID) {
        guard let selectedChoiceID else {
            attemptResult = LessonAttemptResult(
                isCorrect: false,
                feedback: ReviewDomainError.choiceNotFound.localizedDescription
            )
            return
        }

        do {
            let result = try completeReview.execute(
                skillID: skillID,
                choiceID: selectedChoiceID
            )
            items = try loadReviewQueue.execute()
            self.selectedChoiceID = nil
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
