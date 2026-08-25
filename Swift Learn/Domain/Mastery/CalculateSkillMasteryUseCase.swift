//
//  CalculateSkillMasteryUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

struct CalculateSkillMasteryUseCase {
    private let policy: MasteryReviewPolicy
    private let scheduleReview: ScheduleSkillReviewUseCase

    init(policy: MasteryReviewPolicy = .v1) {
        self.policy = policy
        scheduleReview = ScheduleSkillReviewUseCase(policy: policy)
    }

    func execute(
        skillID: SkillID,
        attempts: [LearningAttempt],
        now: Date
    ) -> SkillMasterySnapshot {
        let ordered = attempts.sortedChronologically
        let correct = ordered.filter { $0.evidence.outcome == .correct }
        let incorrectCount = ordered.count - correct.count
        let recallCount = correct.count {
            $0.evidence.activityID.difficulty == .recall
        }
        let challengeCount = correct.count {
            $0.evidence.activityID.difficulty == .challenge
        }
        let evidenceSpan: TimeInterval
        if let first = correct.first, let last = correct.last {
            evidenceSpan = last.recordedAt.timeIntervalSince(first.recordedAt)
        } else {
            evidenceSpan = 0
        }
        let nextReviewAt = scheduleReview.execute(attempts: ordered)

        let baseLevel: MasteryLevel
        if correct.count >= policy.masteredCorrectCount,
           recallCount >= policy.masteredRecallCount,
           challengeCount >= policy.masteredChallengeCount,
           evidenceSpan >= policy.masteredEvidenceSpan {
            baseLevel = .mastered
        } else if correct.count >= policy.proficientCorrectCount,
                  recallCount >= policy.proficientRecallCount,
                  evidenceSpan >= policy.proficientEvidenceSpan {
            baseLevel = .proficient
        } else if correct.count >= 2 {
            baseLevel = .practicing
        } else if correct.count == 1 {
            baseLevel = .introduced
        } else {
            baseLevel = .unseen
        }

        let level: MasteryLevel
        if let nextReviewAt, nextReviewAt <= now {
            level = .reviewDue
        } else {
            level = baseLevel
        }

        return SkillMasterySnapshot(
            id: skillID,
            level: level,
            correctAttemptCount: correct.count,
            incorrectAttemptCount: incorrectCount,
            lastAttemptAt: ordered.last?.recordedAt,
            nextReviewAt: nextReviewAt
        )
    }
}
