//
//  LoadLearningJourneyUseCase.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
struct LoadLearningJourneyUseCase {
    private let contentRepository: any LearningContentRepository
    private let progressRepository: any LearningProgressRepository

    init(
        contentRepository: any LearningContentRepository,
        progressRepository: any LearningProgressRepository
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
    }

    func execute() throws -> LearningJourney {
        LearningJourney(
            catalog: try contentRepository.loadCatalog(),
            completedLessonIDs: try progressRepository.loadCompletedLessonIDs()
        )
    }
}
