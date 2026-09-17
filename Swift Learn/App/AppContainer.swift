//
//  Swift_LearnApp.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import Foundation
import SwiftData
#if os(iOS)
import OSLog
#endif

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let introViewModel: IntroViewModel
    let learningJourneyViewModel: LearningJourneyViewModel
    let bossChallengeViewModel: BossChallengeViewModel
    let projectViewModel: LearningProjectViewModel
    let learnerProfileViewModel: LearnerProfileViewModel
    let reviewQueueViewModel: ReviewQueueViewModel
    let mistakeNotebookViewModel: MistakeNotebookViewModel
    let learningDiscoveryViewModel: LearningDiscoveryViewModel
    let supplementalTracksViewModel: SupplementalTracksViewModel
#if os(iOS)
    private let createWatchLearningSnapshot: CreateWatchLearningSnapshotUseCase
    private let watchSnapshotPublisher: any WatchLearningSnapshotPublishing
    private let watchSyncLogger = Logger(
        subsystem: "com.ata.Swift-Learn",
        category: "AppleWatchSync"
    )
#endif

    init(
        isStoredInMemoryOnly: Bool = false,
        showsIntro: Bool = true,
        storageName: String? = nil,
        storageURL: URL? = nil,
        resetsStoredData: Bool = false,
        seedsReviewFixture: Bool = false,
        seedsActivityFixture: Bool = false,
        seedsCodeOrderingFixture: Bool = false,
        activityFixtureKind: LearningActivityKind? = nil,
        seedsBossFixture: Bool = false,
        seedsLevelCompletionFixture: Bool = false,
        seedsProjectFixture: Bool = false,
        failsFirstBossCompletionSave: Bool = false,
        initialDiscoveryQuery: String = "",
        clock: any LearningClock = SystemLearningClock(),
        idGenerator: any LearningAttemptIDGenerating = SystemLearningAttemptIDGenerator(),
        projectSubmissionIDGenerator: any LearningProjectSubmissionIDGenerating
            = SystemLearningProjectSubmissionIDGenerator()
    ) throws {
        let schema = Schema(versionedSchema: SwiftLearnSchemaV7.self)
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
        let projectRepository = ContentLearningProjectRepository(
            contentRepository: contentRepository
        )
        let skillRepository = ContentCanonicalSkillRepository(
            contentRepository: contentRepository,
            projectRepository: projectRepository
        )
        let attemptRepository = SwiftDataLearningAttemptRepository(
            modelContext: modelContainer.mainContext
        )
        let syncRepository = SwiftDataLearningSyncRepository(
            modelContext: modelContainer.mainContext
        )
        let resetRepository = SwiftDataLearningResetRepository(
            modelContext: modelContainer.mainContext,
            syncGeneration: syncRepository
        )
        let projectSubmissionRepository = SwiftDataLearningProjectSubmissionRepository(
            modelContext: modelContainer.mainContext
        )
        let storedBossCompletionRepository = SwiftDataBossChallengeCompletionRepository(
            modelContext: modelContainer.mainContext
        )
        let bossCompletionRepository: any BossChallengeCompletionRepository =
            failsFirstBossCompletionSave
                ? FailFirstBossChallengeCompletionRepository(
                    repository: storedBossCompletionRepository
                )
                : storedBossCompletionRepository
        let catalog = try contentRepository.loadCatalog()
        let requestedActivityFixtureKind = activityFixtureKind
            ?? (seedsCodeOrderingFixture ? .codeOrdering : nil)
            ?? (seedsActivityFixture ? .outputPrediction : nil)
        if let requestedActivityFixtureKind {
            let lessons = catalog.lessons
            guard let activityIndex = lessons.firstIndex(where: {
                $0.activity.kind == requestedActivityFixtureKind
            }) else {
                throw AppContainerError.activityFixtureUnavailable
            }
            for prerequisite in lessons[..<activityIndex] {
                try progressRepository.markCompleted(lessonID: prerequisite.id)
            }
        }
        if seedsBossFixture {
            guard let firstLevel = catalog.levels.first else {
                throw AppContainerError.bossFixtureUnavailable
            }
            for lesson in firstLevel.lessons {
                try progressRepository.markCompleted(lessonID: lesson.id)
            }
        }
        if seedsLevelCompletionFixture {
            guard let firstLevel = catalog.levels.first,
                  firstLevel.lessons.count > 1 else {
                throw AppContainerError.levelCompletionFixtureUnavailable
            }
            for lesson in firstLevel.lessons.dropLast() {
                try progressRepository.markCompleted(lessonID: lesson.id)
            }
        }
        if seedsProjectFixture {
            let project = try projectRepository.loadProjects().first
            guard let project else {
                throw AppContainerError.projectFixtureUnavailable
            }
            for requirement in project.requirements {
                try progressRepository.markCompleted(lessonID: requirement.lesson.id)
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
        guard let firstLevelID = catalog.levels.first?.id else {
            throw AppContainerError.bossFixtureUnavailable
        }
        let loadBossChallenge = LoadBossChallengeUseCase(
            contentRepository: contentRepository,
            progressRepository: progressRepository,
            loadCanonicalSkills: loadCanonicalSkills
        )
        let loadProject = LoadLearningProjectUseCase(
            projectRepository: projectRepository,
            progressRepository: progressRepository,
            submissionRepository: projectSubmissionRepository
        )
        if seedsReviewFixture && resetsStoredData,
           let lesson = requestedActivityFixtureKind.flatMap({ kind in
               catalog.lessons.first { $0.activity.kind == kind }
           }) ?? catalog.lessons.first {
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
        let loadJourney = LoadLearningJourneyUseCase(
            contentRepository: contentRepository,
            progressRepository: progressRepository
        )
        let loadProfile = LoadLearnerProfileUseCase(
            contentRepository: contentRepository,
            progressRepository: progressRepository,
            profileRepository: profileRepository
        )

        self.modelContainer = modelContainer
        introViewModel = IntroViewModel(
            isPresented: showsIntro,
            sourceDisclosure: LearningSourceDisclosure(catalog: catalog)
        )
        learningJourneyViewModel = LearningJourneyViewModel(
            loadJourney: loadJourney,
            submitAnswer: SubmitLessonAnswerUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository
            ),
            recordAttempt: recordAttempt,
            calculateProgressEvents: CalculateLearningProgressEventsUseCase(
                calculateAchievements: CalculateAchievementsUseCase()
            )
        )
        bossChallengeViewModel = BossChallengeViewModel(
            levelID: firstLevelID,
            loadChallenge: loadBossChallenge,
            submitAnswer: SubmitBossChallengeAnswerUseCase(
                loadChallenge: loadBossChallenge,
                recordAttempt: recordAttempt
            ),
            completeChallenge: CompleteBossChallengeUseCase(
                loadChallenge: loadBossChallenge,
                completionRepository: bossCompletionRepository,
                clock: clock
            )
        )
        projectViewModel = LearningProjectViewModel(
            projectID: ContentLearningProjectRepository.foundationsProjectID,
            loadProject: loadProject,
            submitProject: SubmitLearningProjectUseCase(
                loadProject: loadProject,
                loadCanonicalSkills: loadCanonicalSkills,
                submissionRepository: projectSubmissionRepository,
                clock: clock,
                attemptIDGenerator: idGenerator,
                submissionIDGenerator: projectSubmissionIDGenerator
            )
        )
        learnerProfileViewModel = LearnerProfileViewModel(
            loadProfile: loadProfile,
            loadMasteryOverview: LoadMasteryOverviewUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attemptRepository,
                clock: clock
            ),
            loadRecentActivity: LoadRecentLearningActivityUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attemptRepository
            ),
            loadExperienceAchievements: LoadExperienceAchievementsUseCase(
                bossLevelIDs: [firstLevelID],
                loadBossChallenge: loadBossChallenge,
                bossCompletionRepository: bossCompletionRepository,
                projectRepository: projectRepository,
                projectSubmissionRepository: projectSubmissionRepository
            ),
            loadMotivationProgress: LoadMotivationProgressUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository,
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attemptRepository,
                bossCompletionRepository: bossCompletionRepository,
                projectRepository: projectRepository,
                projectSubmissionRepository: projectSubmissionRepository,
                clock: clock
            ),
            updateProfile: UpdateLearnerProfileUseCase(
                profileRepository: profileRepository
            ),
            updateBadgeShowcase: UpdateLearnerBadgeShowcaseUseCase(
                profileRepository: profileRepository
            ),
            resetLearningProgress: ResetLearningProgressUseCase(
                resetRepository: resetRepository
            ),
            createDataReport: CreateLearnerDataReportUseCase()
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
        let learningDiscoveryViewModel = LearningDiscoveryViewModel(
            loadDiscovery: LoadLearningDiscoveryUseCase(
                contentRepository: contentRepository,
                loadCanonicalSkills: loadCanonicalSkills
            ),
            searchDiscovery: SearchLearningDiscoveryUseCase()
        )
        learningDiscoveryViewModel.query = initialDiscoveryQuery
        self.learningDiscoveryViewModel = learningDiscoveryViewModel
        supplementalTracksViewModel = SupplementalTracksViewModel(
            loadTracks: LoadSupplementalTracksUseCase(
                repository: BundledSupplementalTrackRepository()
            ),
            evaluatePractice: EvaluateSupplementalPracticeUseCase(),
            evaluateLab: EvaluateSupplementalAuthoredLabUseCase()
        )
#if os(iOS)
        let createWatchLearningSnapshot = CreateWatchLearningSnapshotUseCase(
            loadJourney: loadJourney,
            loadProfile: loadProfile,
            loadReviewQueue: loadReviewQueue,
            loadSyncSnapshot: LoadLearningSyncSnapshotUseCase(
                repository: syncRepository
            ),
            clock: clock
        )
        self.createWatchLearningSnapshot = createWatchLearningSnapshot
        let mergeSyncEvents = MergeLearningSyncEventsUseCase(
            repository: syncRepository,
            validator: ValidateLearningSyncEventUseCase(
                contentRepository: contentRepository,
                loadCanonicalSkills: loadCanonicalSkills
            )
        )
        watchSnapshotPublisher = WatchConnectivitySnapshotPublisher(
            receiveEvents: { events in
                _ = try mergeSyncEvents.execute(events)
                return try createWatchLearningSnapshot.execute()
            }
        )
#endif
    }

#if os(iOS)
    func syncAppleWatch() {
        do {
            watchSnapshotPublisher.activate()
            try watchSnapshotPublisher.publish(
                createWatchLearningSnapshot.execute()
            )
        } catch {
            watchSyncLogger.error(
                "Could not prepare Apple Watch snapshot: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
#endif

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
        for record in try modelContext.fetch(
            FetchDescriptor<LearnerBadgeShowcaseRecord>()
        ) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<LearningAttemptRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(
            FetchDescriptor<LearningProjectSubmissionRecord>()
        ) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(
            FetchDescriptor<BossChallengeCompletionRecord>()
        ) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(
            FetchDescriptor<LearningSyncStateRecord>()
        ) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(
            FetchDescriptor<LearningSyncEventReceiptRecord>()
        ) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}

private enum AppContainerError: LocalizedError {
    case activityFixtureUnavailable
    case bossFixtureUnavailable
    case levelCompletionFixtureUnavailable
    case bossCompletionFixtureFailure
    case projectFixtureUnavailable

    var errorDescription: String? {
        switch self {
        case .activityFixtureUnavailable:
            "The UI-test activity fixture has no output-prediction lesson."
        case .bossFixtureUnavailable:
            "The boss challenge fixture has no learning level."
        case .levelCompletionFixtureUnavailable:
            "The UI-test level-completion fixture needs at least two lessons."
        case .bossCompletionFixtureFailure:
            "The UI-test boss achievement could not be saved."
        case .projectFixtureUnavailable:
            "The guided project fixture is unavailable."
        }
    }
}

@MainActor
private final class FailFirstBossChallengeCompletionRepository:
    BossChallengeCompletionRepository {
    private let repository: any BossChallengeCompletionRepository
    private var shouldFail = true

    init(repository: any BossChallengeCompletionRepository) {
        self.repository = repository
    }

    func record(_ completion: BossChallengeCompletion) throws {
        if shouldFail {
            shouldFail = false
            throw AppContainerError.bossCompletionFixtureFailure
        }
        try repository.record(completion)
    }

    func loadCompletions() throws -> [BossChallengeCompletion] {
        try repository.loadCompletions()
    }
}
