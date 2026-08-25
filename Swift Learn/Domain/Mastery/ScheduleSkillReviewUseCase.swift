//
//  ScheduleSkillReviewUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

struct ScheduleSkillReviewUseCase {
    let policy: MasteryReviewPolicy

    init(policy: MasteryReviewPolicy = .v1) {
        self.policy = policy
    }

    func execute(attempts: [LearningAttempt]) -> Date? {
        guard let latest = attempts.sortedChronologically.last else { return nil }
        guard latest.evidence.outcome == .correct else {
            return latest.recordedAt.addingTimeInterval(policy.incorrectDelay)
        }

        let correctCount = attempts.count { $0.evidence.outcome == .correct }
        let index = min(
            max(correctCount - 1, 0),
            policy.guidedCorrectDelays.count - 1
        )
        var delay = policy.guidedCorrectDelays[index]
        switch latest.evidence.activityID.difficulty {
        case .guided:
            break
        case .recall:
            delay = max(delay, policy.minimumRecallDelay)
        case .challenge:
            delay = max(delay, policy.minimumChallengeDelay)
        }
        return latest.recordedAt.addingTimeInterval(delay)
    }
}

extension Array where Element == LearningAttempt {
    var sortedChronologically: [LearningAttempt] {
        sorted {
            if $0.recordedAt == $1.recordedAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.recordedAt < $1.recordedAt
        }
    }
}
