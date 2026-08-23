//
//  Swift_LearnApp.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let learningJourneyViewModel: LearningJourneyViewModel
    let learnerProfileViewModel: LearnerProfileViewModel

    init(isStoredInMemoryOnly: Bool = false) throws {
        let schema = Schema([
            LessonProgressRecord.self,
            LearnerProfileRecord.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        let modelContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let contentRepository = BundledLearningContentRepository(
            bundle: Bundle(for: AppContainer.self)
        )
        let progressRepository = SwiftDataLearningProgressRepository(
            modelContext: modelContainer.mainContext
        )
        let profileRepository = SwiftDataLearnerProfileRepository(
            modelContext: modelContainer.mainContext
        )

        self.modelContainer = modelContainer
        learningJourneyViewModel = LearningJourneyViewModel(
            loadJourney: LoadLearningJourneyUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository
            ),
            submitAnswer: SubmitLessonAnswerUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository
            ),
            calculateProgressEvents: CalculateLearningProgressEventsUseCase(
                calculateAchievements: CalculateAchievementsUseCase()
            )
        )
        learnerProfileViewModel = LearnerProfileViewModel(
            loadProfile: LoadLearnerProfileUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository,
                profileRepository: profileRepository
            ),
            updateProfile: UpdateLearnerProfileUseCase(
                profileRepository: profileRepository
            )
        )
    }
}
