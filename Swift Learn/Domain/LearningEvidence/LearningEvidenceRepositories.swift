//
//  LearningEvidenceRepositories.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

@MainActor
protocol LearningAttemptRepository {
    func record(_ attempt: LearningAttempt) throws
    func loadAttempts(skillID: SkillID) throws -> [LearningAttempt]
    func loadAllAttempts() throws -> [LearningAttempt]
}

@MainActor
protocol CanonicalSkillRepository {
    func loadCanonicalSkills() throws -> [CanonicalSkill]
}
