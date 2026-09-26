//
//  BossChallengeViewModel.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class BossChallengeViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let levelID: String
    private(set) var loadState: LoadState = .idle
    private(set) var availability: BossChallengeAvailability?
    private(set) var selectedChoiceID: String?
    private(set) var currentItemIndex = 0
    private(set) var answerResults: [BossChallengeAnswerResult] = []
    private(set) var result: BossChallengeResult?
    private(set) var errorMessage: String?
    private(set) var completionSaveError: String?
    private(set) var attemptRevision = 0
    /// Bumped when the challenge being ordered changes. `startSession()` runs
    /// from `onAppear`, which SwiftUI may fire again for the same challenge.
    private(set) var choiceOrderRevision = 0
    private var orderedQuestionID: String?

    private let loadChallenge: LoadBossChallengeUseCase
    private let submitAnswer: SubmitBossChallengeAnswerUseCase
    private let completeChallenge: CompleteBossChallengeUseCase
    private let orderChoices: OrderActivityChoicesUseCase

    init(
        levelID: String,
        loadChallenge: LoadBossChallengeUseCase,
        submitAnswer: SubmitBossChallengeAnswerUseCase,
        completeChallenge: CompleteBossChallengeUseCase,
        orderChoices: OrderActivityChoicesUseCase = OrderActivityChoicesUseCase(
            randomizer: IdentityChoiceOrder()
        )
    ) {
        self.levelID = levelID
        self.loadChallenge = loadChallenge
        self.submitAnswer = submitAnswer
        self.completeChallenge = completeChallenge
        self.orderChoices = orderChoices
    }

    /// The answers for `item` in display order. Deterministic for a given item
    /// and `choiceOrderRevision`, so a redraw never reorders anything.
    func orderedChoices(for item: BossChallengeItem) -> [LearningChoice] {
        orderChoices.execute(
            item.lesson.activity.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: item.id,
                attemptNumber: choiceOrderRevision
            )
        )
    }

    func load() {
        loadState = .loading
        do {
            availability = try loadChallenge.execute(levelID: levelID)
            loadState = .loaded
        } catch {
            availability = nil
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Called from `onAppear`, which SwiftUI fires again for the challenge
    /// already on screen. Restarting then would discard answers the learner
    /// has already given, so only a new challenge starts a session.
    func startSession() {
        let questionID = availability?.challenge.items.first?.id
        guard orderedQuestionID != questionID || result != nil else { return }
        orderedQuestionID = questionID
        choiceOrderRevision += 1
        selectedChoiceID = nil
        currentItemIndex = 0
        answerResults = []
        result = nil
        errorMessage = nil
        completionSaveError = nil
    }

    func selectChoice(_ choiceID: String) {
        selectedChoiceID = choiceID
        errorMessage = nil
    }

    func submitCurrentAnswer() {
        guard let item = currentItem,
              let selectedChoiceID else {
            errorMessage = BossChallengeDomainError.choiceNotFound.localizedDescription
            return
        }

        do {
            let answer = try submitAnswer.execute(
                levelID: levelID,
                itemID: item.id,
                choiceID: selectedChoiceID
            )
            answerResults.append(answer)
            attemptRevision += 1
            self.selectedChoiceID = nil
            errorMessage = nil

            if currentItemIndex + 1 < (availability?.challenge.items.count ?? 0) {
                currentItemIndex += 1
            } else {
                result = BossChallengeResult(answers: answerResults)
                saveCompletion()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retryCompletionSave() {
        guard result != nil else { return }
        saveCompletion()
    }

    var currentItem: BossChallengeItem? {
        guard let items = availability?.challenge.items,
              items.indices.contains(currentItemIndex),
              result == nil else {
            return nil
        }
        return items[currentItemIndex]
    }

    var stepSummary: String {
        guard let total = availability?.challenge.items.count, total > 0 else {
            return ""
        }
        return "Challenge \(currentItemIndex + 1) of \(total)"
    }

    private func saveCompletion() {
        do {
            result = try completeChallenge.execute(
                levelID: levelID,
                answers: answerResults
            )
            completionSaveError = nil
        } catch {
            completionSaveError = error.localizedDescription
        }
    }
}
