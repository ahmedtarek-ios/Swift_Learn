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

    private let loadChallenge: LoadBossChallengeUseCase
    private let submitAnswer: SubmitBossChallengeAnswerUseCase
    private let completeChallenge: CompleteBossChallengeUseCase

    init(
        levelID: String,
        loadChallenge: LoadBossChallengeUseCase,
        submitAnswer: SubmitBossChallengeAnswerUseCase,
        completeChallenge: CompleteBossChallengeUseCase
    ) {
        self.levelID = levelID
        self.loadChallenge = loadChallenge
        self.submitAnswer = submitAnswer
        self.completeChallenge = completeChallenge
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

    func startSession() {
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
