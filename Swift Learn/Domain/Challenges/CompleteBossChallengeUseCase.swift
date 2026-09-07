//
//  CompleteBossChallengeUseCase.swift
//  Swift Learn
//
//  Created by Codex on 07/09/2026.
//

@MainActor
struct CompleteBossChallengeUseCase {
    private let loadChallenge: LoadBossChallengeUseCase
    private let completionRepository: any BossChallengeCompletionRepository
    private let clock: any LearningClock

    init(
        loadChallenge: LoadBossChallengeUseCase,
        completionRepository: any BossChallengeCompletionRepository,
        clock: any LearningClock
    ) {
        self.loadChallenge = loadChallenge
        self.completionRepository = completionRepository
        self.clock = clock
    }

    func execute(
        levelID: String,
        answers: [BossChallengeAnswerResult]
    ) throws -> BossChallengeResult {
        let availability = try loadChallenge.execute(levelID: levelID)
        guard availability.isUnlocked else {
            throw BossChallengeDomainError.challengeLocked
        }

        let answersByItemID = try answers.reduce(
            into: [String: BossChallengeAnswerResult]()
        ) { result, answer in
            guard result[answer.itemID] == nil else {
                throw BossChallengeDomainError.duplicateAnswer(answer.itemID)
            }
            result[answer.itemID] = answer
        }
        let orderedAnswers = try availability.challenge.items.map { item in
            guard let answer = answersByItemID[item.id] else {
                throw BossChallengeDomainError.incompleteSession
            }
            return answer
        }
        guard answersByItemID.count == availability.challenge.items.count else {
            throw BossChallengeDomainError.incompleteSession
        }

        let result = BossChallengeResult(answers: orderedAnswers)
        if result.isPassed {
            try completionRepository.record(
                BossChallengeCompletion(
                    challengeID: availability.challenge.id,
                    levelID: availability.challenge.levelID,
                    completedAt: clock.now
                )
            )
        }
        return result
    }
}
