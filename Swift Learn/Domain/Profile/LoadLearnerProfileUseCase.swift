//
//  LoadLearnerProfileUseCase.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
struct LoadLearnerProfileUseCase {
    private let contentRepository: any LearningContentRepository
    private let progressRepository: any LearningProgressRepository
    private let profileRepository: any LearnerProfileRepository
    private let calculateAchievements: CalculateAchievementsUseCase

    init(
        contentRepository: any LearningContentRepository,
        progressRepository: any LearningProgressRepository,
        profileRepository: any LearnerProfileRepository,
        calculateAchievements: CalculateAchievementsUseCase = CalculateAchievementsUseCase()
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
        self.profileRepository = profileRepository
        self.calculateAchievements = calculateAchievements
    }

    func execute() throws -> LearnerProfileSnapshot {
        let journey = LearningJourney(
            catalog: try contentRepository.loadCatalog(),
            completedLessonIDs: try progressRepository.loadCompletedLessonIDs()
        )

        return LearnerProfileSnapshot(
            profile: try profileRepository.loadProfile(),
            journey: journey,
            achievements: calculateAchievements.execute(journey: journey)
        )
    }
}
