//
//  LoadReviewQueueUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

struct LoadReviewQueueUseCase {
    private let contentRepository: any LearningContentRepository
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository
    private let clock: any LearningClock
    private let policy: MasteryReviewPolicy
    private let scheduleReview: ScheduleSkillReviewUseCase
    private let calculateMastery: CalculateSkillMasteryUseCase

    init(
        contentRepository: any LearningContentRepository,
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository,
        clock: any LearningClock,
        policy: MasteryReviewPolicy = .v1
    ) {
        self.contentRepository = contentRepository
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
        self.clock = clock
        self.policy = policy
        scheduleReview = ScheduleSkillReviewUseCase(policy: policy)
        calculateMastery = CalculateSkillMasteryUseCase(policy: policy)
    }

    func execute() throws -> [ReviewItem] {
        let catalog = try contentRepository.loadCatalog()
        let skills = try loadCanonicalSkills.execute()
        let attemptsBySkill = Dictionary(
            grouping: try attemptRepository.loadAllAttempts(),
            by: { $0.evidence.skillID }
        )

        return try skills.compactMap { skill -> ReviewItem? in
            let attempts = attemptsBySkill[skill.id, default: []]
            guard let dueAt = scheduleReview.execute(attempts: attempts),
                  dueAt <= clock.now else {
                return nil
            }
            guard let lessonID = skill.lessonIDs.sorted().first,
                  let lesson = catalog.lesson(id: lessonID) else {
                throw ReviewDomainError.lessonUnavailable(skill.id.rawValue)
            }
            let status: ReviewStatus = clock.now.timeIntervalSince(dueAt)
                > policy.overdueThreshold ? .overdue : .due
            return ReviewItem(
                skill: skill,
                lesson: lesson,
                mastery: calculateMastery.execute(
                    skillID: skill.id,
                    attempts: attempts,
                    now: clock.now
                ),
                dueAt: dueAt,
                status: status
            )
        }
        .sorted {
            if $0.status != $1.status {
                return $0.status == .overdue
            }
            if $0.dueAt != $1.dueAt {
                return $0.dueAt < $1.dueAt
            }
            return $0.id.rawValue < $1.id.rawValue
        }
    }
}
