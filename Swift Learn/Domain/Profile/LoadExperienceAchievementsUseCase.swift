//
//  LoadExperienceAchievementsUseCase.swift
//  Swift Learn
//
//  Created by Codex on 07/09/2026.
//

@MainActor
struct LoadExperienceAchievementsUseCase {
    private let bossLevelIDs: [String]
    private let loadBossChallenge: LoadBossChallengeUseCase
    private let bossCompletionRepository: any BossChallengeCompletionRepository
    private let projectRepository: any LearningProjectRepository
    private let projectSubmissionRepository: any LearningProjectSubmissionRepository

    init(
        bossLevelIDs: [String],
        loadBossChallenge: LoadBossChallengeUseCase,
        bossCompletionRepository: any BossChallengeCompletionRepository,
        projectRepository: any LearningProjectRepository,
        projectSubmissionRepository: any LearningProjectSubmissionRepository
    ) {
        self.bossLevelIDs = bossLevelIDs
        self.loadBossChallenge = loadBossChallenge
        self.bossCompletionRepository = bossCompletionRepository
        self.projectRepository = projectRepository
        self.projectSubmissionRepository = projectSubmissionRepository
    }

    func execute() throws -> [AchievementProgress] {
        let completedChallengeIDs = Set(
            try bossCompletionRepository.loadCompletions().map(\.challengeID)
        )
        let bossAchievements = try bossLevelIDs.map { levelID in
            let challenge = try loadBossChallenge.execute(levelID: levelID).challenge
            return AchievementProgress(
                definition: AchievementDefinition(
                    id: "achievement.\(challenge.id)",
                    title: challenge.title,
                    summary: "Pass every item in \(challenge.title).",
                    kind: .bossChallenge(challenge.id)
                ),
                completedRequirementCount: completedChallengeIDs.contains(challenge.id) ? 1 : 0,
                totalRequirementCount: 1
            )
        }

        let projectAchievements = try projectRepository.loadProjects().map { project in
            let isEarned = try projectSubmissionRepository
                .loadSubmissions(projectID: project.id)
                .contains(where: \.isPassed)
            return AchievementProgress(
                definition: AchievementDefinition(
                    id: "achievement.project.\(project.id)",
                    title: project.title,
                    summary: "Pass every requirement in \(project.title).",
                    kind: .guidedProject(project.id)
                ),
                completedRequirementCount: isEarned ? 1 : 0,
                totalRequirementCount: 1
            )
        }

        return bossAchievements + projectAchievements
    }
}
