//
//  LoadSkillAttemptHistoryUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

@MainActor
struct LoadSkillAttemptHistoryUseCase {
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository

    init(
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository
    ) {
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
    }

    func execute(skillID: SkillID) throws -> [LearningAttempt] {
        let skills = try loadCanonicalSkills.execute()
        guard skills.contains(where: { $0.id == skillID }) else {
            throw LearningEvidenceDomainError.unknownSkillID(skillID.rawValue)
        }

        return try attemptRepository.loadAttempts(skillID: skillID).sorted {
            if $0.recordedAt == $1.recordedAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.recordedAt < $1.recordedAt
        }
    }
}
