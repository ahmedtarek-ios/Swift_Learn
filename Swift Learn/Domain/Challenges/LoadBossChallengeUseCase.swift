//
//  LoadBossChallengeUseCase.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

@MainActor
struct LoadBossChallengeUseCase {
    private let contentRepository: any LearningContentRepository
    private let progressRepository: any LearningProgressRepository
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let policy: BossChallengePolicy

    init(
        contentRepository: any LearningContentRepository,
        progressRepository: any LearningProgressRepository,
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        policy: BossChallengePolicy = .v1
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
        self.loadCanonicalSkills = loadCanonicalSkills
        self.policy = policy
    }

    func execute(levelID: String) throws -> BossChallengeAvailability {
        let catalog = try contentRepository.loadCatalog()
        guard let level = catalog.levels.first(where: { $0.id == levelID }) else {
            throw BossChallengeDomainError.levelNotFound(levelID)
        }
        guard level.lessons.count >= policy.itemCount else {
            throw BossChallengeDomainError.insufficientSkills(
                required: policy.itemCount,
                available: level.lessons.count
            )
        }

        let skills = try loadCanonicalSkills.execute()
        let items = try level.lessons.prefix(policy.itemCount).map { lesson in
            guard let skill = skills.first(where: { $0.lessonIDs.contains(lesson.id) }) else {
                throw BossChallengeDomainError.skillMappingNotFound(lesson.id)
            }
            return BossChallengeItem(
                id: lesson.id,
                lesson: lesson,
                skillID: skill.id
            )
        }
        let completedLessonIDs = try progressRepository.loadCompletedLessonIDs()
        let completedRequirementCount = level.lessons.count {
            completedLessonIDs.contains($0.id)
        }

        return BossChallengeAvailability(
            challenge: BossChallenge(
                id: "boss.\(level.id)",
                levelID: level.id,
                title: "\(level.title) Boss Challenge",
                summary: "Prove two skills together without lesson hints.",
                items: items
            ),
            isUnlocked: completedRequirementCount == level.lessons.count,
            completedRequirementCount: completedRequirementCount,
            totalRequirementCount: level.lessons.count
        )
    }
}
