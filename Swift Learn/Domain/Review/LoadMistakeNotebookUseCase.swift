//
//  LoadMistakeNotebookUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

struct LoadMistakeNotebookUseCase {
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository

    init(
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository
    ) {
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
    }

    func execute() throws -> [MistakeNotebookEntry] {
        let skills = try loadCanonicalSkills.execute()
        let skillsByID = Dictionary(uniqueKeysWithValues: skills.map { ($0.id, $0) })
        let incorrect = try attemptRepository.loadAllAttempts().filter {
            $0.evidence.outcome == .incorrect
        }
        return Dictionary(grouping: incorrect, by: { $0.evidence.skillID })
            .compactMap { skillID, attempts in
                guard let skill = skillsByID[skillID] else { return nil }
                return MistakeNotebookEntry(
                    skillID: skillID,
                    title: skill.title,
                    attempts: attempts.sortedChronologically
                )
            }
            .sorted {
                let leftDate = $0.attempts.last?.recordedAt ?? .distantPast
                let rightDate = $1.attempts.last?.recordedAt ?? .distantPast
                if leftDate != rightDate {
                    return leftDate > rightDate
                }
                return $0.id.rawValue < $1.id.rawValue
            }
    }
}
