//
//  SubmitBossChallengeAnswerUseCase.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

@MainActor
struct SubmitBossChallengeAnswerUseCase {
    private let loadChallenge: LoadBossChallengeUseCase
    private let recordAttempt: RecordLearningAttemptUseCase

    init(
        loadChallenge: LoadBossChallengeUseCase,
        recordAttempt: RecordLearningAttemptUseCase
    ) {
        self.loadChallenge = loadChallenge
        self.recordAttempt = recordAttempt
    }

    func execute(
        levelID: String,
        itemID: String,
        choiceID: String
    ) throws -> BossChallengeAnswerResult {
        let availability = try loadChallenge.execute(levelID: levelID)
        guard availability.isUnlocked else {
            throw BossChallengeDomainError.challengeLocked
        }
        guard let item = availability.challenge.items.first(where: { $0.id == itemID }) else {
            throw BossChallengeDomainError.itemNotFound(itemID)
        }
        guard item.lesson.choice(id: choiceID) != nil else {
            throw BossChallengeDomainError.choiceNotFound
        }

        let isCorrect = item.lesson.correctChoiceID == choiceID
        try recordAttempt.execute(
            lessonID: item.lesson.id,
            activityID: .challenge(skillID: item.skillID),
            outcome: isCorrect ? .correct : .incorrect
        )
        return BossChallengeAnswerResult(
            itemID: item.id,
            isCorrect: isCorrect,
            feedback: isCorrect
                ? "Skill verified. Continue the boss challenge."
                : "This result was added to your review plan."
        )
    }
}
