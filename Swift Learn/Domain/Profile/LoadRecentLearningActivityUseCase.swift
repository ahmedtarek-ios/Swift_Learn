//
//  LoadRecentLearningActivityUseCase.swift
//  Swift Learn
//
//  Created by Codex on 06/09/2026.
//

import Foundation

enum RecentLearningActivityKind: Equatable, Sendable {
    case lesson
    case review
    case bossChallenge
    case guidedProject
}

struct RecentLearningActivity: Identifiable, Equatable, Sendable {
    let id: UUID
    let skillID: SkillID
    let skillTitle: String
    let kind: RecentLearningActivityKind
    let outcome: AttemptOutcome
    let recordedAt: Date
}

@MainActor
struct LoadRecentLearningActivityUseCase {
    static let maximumActivityCount = 5

    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository

    init(
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository
    ) {
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
    }

    func execute() throws -> [RecentLearningActivity] {
        let skillsByID = Dictionary(
            uniqueKeysWithValues: try loadCanonicalSkills.execute().map { ($0.id, $0) }
        )

        return try attemptRepository.loadAllAttempts()
            .compactMap { attempt in
                guard let skill = skillsByID[attempt.evidence.skillID],
                      skill.lessonIDs.contains(attempt.evidence.lessonID),
                      skill.activityIDs.contains(attempt.evidence.activityID) else {
                    return nil
                }

                return RecentLearningActivity(
                    id: attempt.id,
                    skillID: skill.id,
                    skillTitle: skill.title,
                    kind: kind(for: attempt.evidence.activityID, skillID: skill.id),
                    outcome: attempt.evidence.outcome,
                    recordedAt: attempt.recordedAt
                )
            }
            .sorted { left, right in
                if left.recordedAt != right.recordedAt {
                    return left.recordedAt > right.recordedAt
                }
                return left.id.uuidString < right.id.uuidString
            }
            .prefix(Self.maximumActivityCount)
            .map { $0 }
    }

    private func kind(
        for activityID: LearningActivityID,
        skillID: SkillID
    ) -> RecentLearningActivityKind {
        if activityID == .review(skillID: skillID) {
            return .review
        }
        if activityID == .challenge(skillID: skillID) {
            return .bossChallenge
        }
        if activityID.isProjectActivity(for: skillID) {
            return .guidedProject
        }
        return .lesson
    }
}
