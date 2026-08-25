//
//  LoadMasteryOverviewUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

struct LoadMasteryOverviewUseCase {
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository
    private let clock: any LearningClock
    private let calculateMastery: CalculateSkillMasteryUseCase

    init(
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository,
        clock: any LearningClock,
        policy: MasteryReviewPolicy = .v1
    ) {
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
        self.clock = clock
        calculateMastery = CalculateSkillMasteryUseCase(policy: policy)
    }

    func execute() throws -> MasteryOverview {
        let attemptsBySkill = Dictionary(
            grouping: try attemptRepository.loadAllAttempts(),
            by: { $0.evidence.skillID }
        )
        let snapshots = try loadCanonicalSkills.execute()
            .sorted { $0.id.rawValue < $1.id.rawValue }
            .map { skill in
                calculateMastery.execute(
                    skillID: skill.id,
                    attempts: attemptsBySkill[skill.id, default: []],
                    now: clock.now
                )
            }
        return MasteryOverview(snapshots: snapshots)
    }
}
