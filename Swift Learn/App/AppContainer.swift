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
    let introViewModel: IntroViewModel
    let learningJourneyViewModel: LearningJourneyViewModel
    let learnerProfileViewModel: LearnerProfileViewModel
    let reviewQueueViewModel: ReviewQueueViewModel
    let mistakeNotebookViewModel: MistakeNotebookViewModel

    init(
        isStoredInMemoryOnly: Bool = false,
        showsIntro: Bool = true,
        storageName: String? = nil,
        storageURL: URL? = nil,
        resetsStoredData: Bool = false,
        seedsReviewFixture: Bool = false,
        seedsActivityFixture: Bool = false,
        clock: any LearningClock = SystemLearningClock(),
        idGenerator: any LearningAttemptIDGenerating = SystemLearningAttemptIDGenerator()
    ) throws {
        let schema = Schema(versionedSchema: SwiftLearnSchemaV3.self)
        let configuration: ModelConfiguration
        if let storageURL {
            configuration = ModelConfiguration(
                storageName,
                schema: schema,
                url: storageURL,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                storageName,
                schema: schema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                cloudKitDatabase: .none
            )
        }
        let modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: SwiftLearnSchemaMigrationPlan.self,
            configurations: [configuration]
        )
        if resetsStoredData {
            try Self.resetStoredData(in: modelContainer.mainContext)
        }
        let contentRepository = BundledLearningContentRepository(
            bundle: Bundle(for: AppContainer.self)
        )
        let progressRepository = SwiftDataLearningProgressRepository(
            modelContext: modelContainer.mainContext
        )
        let profileRepository = SwiftDataLearnerProfileRepository(
            modelContext: modelContainer.mainContext
        )
        let skillRepository = ContentCanonicalSkillRepository(
            contentRepository: contentRepository
        )
        let attemptRepository = SwiftDataLearningAttemptRepository(
            modelContext: modelContainer.mainContext
        )
        if seedsActivityFixture {
            let lessons = try contentRepository.loadCatalog().lessons
            guard let activityIndex = lessons.firstIndex(where: {
                $0.activity.kind == .outputPrediction
            }) else {
                throw AppContainerError.activityFixtureUnavailable
            }
            for prerequisite in lessons[..<activityIndex] {
                try progressRepository.markCompleted(lessonID: prerequisite.id)
            }
        }
        let loadCanonicalSkills = LoadCanonicalSkillsUseCase(
            contentRepository: contentRepository,
            skillRepository: skillRepository
        )
        let recordAttempt = RecordLearningAttemptUseCase(
            loadCanonicalSkills: loadCanonicalSkills,
            attemptRepository: attemptRepository,
            clock: clock,
            idGenerator: idGenerator
        )
        if seedsReviewFixture && resetsStoredData,
           let lesson = try contentRepository.loadCatalog().lessons.first {
            try recordAttempt.execute(
                lessonID: lesson.id,
                activityID: lesson.activityID,
                outcome: .incorrect,
                errorCategory: .incorrectChoice
            )
        }
        let loadReviewQueue = LoadReviewQueueUseCase(
            contentRepository: contentRepository,
            loadCanonicalSkills: loadCanonicalSkills,
            attemptRepository: attemptRepository,
            clock: clock
        )

        self.modelContainer = modelContainer
        introViewModel = IntroViewModel(isPresented: showsIntro)
        learningJourneyViewModel = LearningJourneyViewModel(
            loadJourney: LoadLearningJourneyUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository
            ),
            submitAnswer: SubmitLessonAnswerUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository
            ),
            recordAttempt: recordAttempt,
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
            loadMasteryOverview: LoadMasteryOverviewUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attemptRepository,
                clock: clock
            ),
            updateProfile: UpdateLearnerProfileUseCase(
                profileRepository: profileRepository
            )
        )
        reviewQueueViewModel = ReviewQueueViewModel(
            loadReviewQueue: loadReviewQueue,
            completeReview: CompleteReviewUseCase(
                loadReviewQueue: loadReviewQueue,
                recordAttempt: recordAttempt
            )
        )
        mistakeNotebookViewModel = MistakeNotebookViewModel(
            loadMistakes: LoadMistakeNotebookUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attemptRepository
            )
        )
    }

    private static func resetStoredData(in modelContext: ModelContext) throws {
        for record in try modelContext.fetch(FetchDescriptor<LessonProgressRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<LearnerProfileRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<LearnerAvatarImageRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<LearningAttemptRecord>()) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}

private enum AppContainerError: LocalizedError {
    case activityFixtureUnavailable

    var errorDescription: String? {
        "The UI-test activity fixture has no output-prediction lesson."
    }
}
