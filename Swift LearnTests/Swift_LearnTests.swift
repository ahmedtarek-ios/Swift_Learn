//
//  Swift_LearnTests.swift
//  Swift LearnTests
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Swift_Learn

@MainActor
struct Swift_LearnTests {
    @Test
    func loadJourneyCombinesCatalogAndProgress() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: ["swift.bindings.constants"]
        )
        let useCase = LoadLearningJourneyUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        let journey = try useCase.execute()

        #expect(journey.catalog.sourceID == "swift-6.4-beta-2026-07-31")
        #expect(journey.completedLessonCount == 1)
        #expect(journey.totalLessonCount == catalog.lessons.count)
        #expect(journey.progress == 1.0 / Double(catalog.lessons.count))
        #expect(journey.isUnlocked(lessonID: "swift.bindings.type-annotations"))
    }

    @Test
    func correctAnswerCompletesLesson() throws {
        let progress = InMemoryLearningProgressRepository()
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: InMemoryLearningContentRepository(
                catalog: try bundledCatalog()
            ),
            progressRepository: progress
        )

        let result = try useCase.execute(
            lessonID: "swift.bindings.constants",
            choiceID: "let"
        )

        #expect(result.isCorrect)
        #expect(progress.completedLessonIDs == ["swift.bindings.constants"])
    }

    @Test
    func incorrectAnswerDoesNotCompleteLesson() throws {
        let progress = InMemoryLearningProgressRepository()
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: InMemoryLearningContentRepository(
                catalog: try bundledCatalog()
            ),
            progressRepository: progress
        )

        let result = try useCase.execute(
            lessonID: "swift.bindings.constants",
            choiceID: "var"
        )

        #expect(!result.isCorrect)
        #expect(progress.completedLessonIDs.isEmpty)
    }

    @Test
    func typeAnnotationsLessonStaysLockedUntilConstantsLessonIsComplete() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository()
        let journey = try LoadLearningJourneyUseCase(
            contentRepository: content,
            progressRepository: progress
        ).execute()
        let submitAnswer = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        #expect(!journey.isUnlocked(lessonID: "swift.bindings.type-annotations"))
        #expect(throws: LearningDomainError.lessonLocked) {
            try submitAnswer.execute(
                lessonID: "swift.bindings.type-annotations",
                choiceID: "string"
            )
        }
        #expect(progress.completedLessonIDs.isEmpty)
    }

    @Test
    func correctTypeAnnotationCompletesUnlockedSecondLesson() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: ["swift.bindings.constants"]
        )
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        let result = try useCase.execute(
            lessonID: "swift.bindings.type-annotations",
            choiceID: "string"
        )

        #expect(result.isCorrect)
        #expect(
            progress.completedLessonIDs == [
                "swift.bindings.constants",
                "swift.bindings.type-annotations"
            ]
        )
    }

    @Test
    func identifierNamingLessonStaysLockedUntilTypeAnnotationsIsComplete() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: ["swift.bindings.constants"]
        )
        let journey = try LoadLearningJourneyUseCase(
            contentRepository: content,
            progressRepository: progress
        ).execute()
        let submitAnswer = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        #expect(!journey.isUnlocked(lessonID: "swift.bindings.identifier-naming"))
        #expect(throws: LearningDomainError.lessonLocked) {
            try submitAnswer.execute(
                lessonID: "swift.bindings.identifier-naming",
                choiceID: "lesson2"
            )
        }
    }

    @Test
    func validIdentifierCompletesUnlockedThirdLesson() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: [
                "swift.bindings.constants",
                "swift.bindings.type-annotations"
            ]
        )
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        let result = try useCase.execute(
            lessonID: "swift.bindings.identifier-naming",
            choiceID: "lesson2"
        )

        #expect(result.isCorrect)
        #expect(progress.completedLessonIDs.count == 3)
        #expect(progress.completedLessonIDs.contains("swift.bindings.identifier-naming"))
    }

    @Test
    func printingLessonStaysLockedUntilIdentifierNamingIsComplete() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: [
                "swift.bindings.constants",
                "swift.bindings.type-annotations"
            ]
        )
        let journey = try LoadLearningJourneyUseCase(
            contentRepository: content,
            progressRepository: progress
        ).execute()
        let submitAnswer = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        #expect(!journey.isUnlocked(lessonID: "swift.output.string-interpolation"))
        #expect(throws: LearningDomainError.lessonLocked) {
            try submitAnswer.execute(
                lessonID: "swift.output.string-interpolation",
                choiceID: "interpolation"
            )
        }
    }

    @Test
    func stringInterpolationCompletesUnlockedFourthLesson() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: [
                "swift.bindings.constants",
                "swift.bindings.type-annotations",
                "swift.bindings.identifier-naming"
            ]
        )
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        let result = try useCase.execute(
            lessonID: "swift.output.string-interpolation",
            choiceID: "interpolation"
        )

        #expect(result.isCorrect)
        #expect(progress.completedLessonIDs.count == 4)
        #expect(progress.completedLessonIDs.contains("swift.output.string-interpolation"))
    }

    @Test
    func commentsLessonStaysLockedUntilPrintingLessonIsComplete() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: [
                "swift.bindings.constants",
                "swift.bindings.type-annotations",
                "swift.bindings.identifier-naming"
            ]
        )
        let journey = try LoadLearningJourneyUseCase(
            contentRepository: content,
            progressRepository: progress
        ).execute()
        let submitAnswer = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        #expect(!journey.isUnlocked(lessonID: "swift.comments.single-line"))
        #expect(throws: LearningDomainError.lessonLocked) {
            try submitAnswer.execute(
                lessonID: "swift.comments.single-line",
                choiceID: "single-line-comment"
            )
        }
    }

    @Test
    func singleLineCommentCompletesUnlockedFifthLesson() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: [
                "swift.bindings.constants",
                "swift.bindings.type-annotations",
                "swift.bindings.identifier-naming",
                "swift.output.string-interpolation"
            ]
        )
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        let result = try useCase.execute(
            lessonID: "swift.comments.single-line",
            choiceID: "single-line-comment"
        )

        #expect(result.isCorrect)
        #expect(progress.completedLessonIDs.count == 5)
        #expect(progress.completedLessonIDs.contains("swift.comments.single-line"))
    }

    @Test
    func unknownChoiceReturnsDomainError() throws {
        let useCase = SubmitLessonAnswerUseCase(
            contentRepository: InMemoryLearningContentRepository(
                catalog: try bundledCatalog()
            ),
            progressRepository: InMemoryLearningProgressRepository()
        )

        #expect(throws: LearningDomainError.choiceNotFound) {
            try useCase.execute(
                lessonID: "swift.bindings.constants",
                choiceID: "unknown"
            )
        }
    }

    @Test
    func viewModelTransitionsFromChoiceToCompletedProgress() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let progress = InMemoryLearningProgressRepository()
        let viewModel = makeViewModel(content: content, progress: progress)

        viewModel.load()
        viewModel.selectChoice("let")
        viewModel.submit(lessonID: "swift.bindings.constants")

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.selectedChoiceID == "let")
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.journey?.completedLessonCount == 1)
        #expect(
            viewModel.recentlyUnlockedLessonID
                == "swift.bindings.type-annotations"
        )
        #expect(viewModel.currentAchievement?.id == "achievement.first-lesson")
        viewModel.dismissCurrentAchievement()
        #expect(viewModel.currentAchievement == nil)
        #expect(
            viewModel.nextLesson(after: "swift.bindings.constants")?.id
                == "swift.bindings.type-annotations"
        )
    }

    @Test
    func viewModelExposesRepositoryFailure() throws {
        let content = InMemoryLearningContentRepository(catalog: try bundledCatalog())
        let viewModel = makeViewModel(
            content: content,
            progress: FailingLearningProgressRepository()
        )

        viewModel.load()

        #expect(viewModel.loadState == .failed("Progress unavailable"))
    }

    @Test
    func bundledContentMapsCanonicalSourceAndLesson() throws {
        let repository = BundledLearningContentRepository(
            bundle: Bundle(for: AppContainer.self)
        )

        let catalog = try repository.loadCatalog()

        #expect(catalog.sourceID == "swift-6.4-beta-2026-07-31")
        #expect(catalog.levels.count == 33)
        #expect(catalog.lessons.count == 486)
        let lessonIDs = catalog.lessons.map(\.id)
        #expect(lessonIDs.count == Set(lessonIDs).count)
        #expect(catalog.lessons.allSatisfy { !$0.choices.isEmpty })
        #expect(catalog.lessons.allSatisfy { !$0.sourceReferences.isEmpty })
        #expect(
            catalog.lessons.first?.sourceReferences.contains(
                "LanguageGuide/TheBasics.xhtml#Declaring-Constants-and-Variables"
            ) == true
        )
        #expect(
            catalog.lesson(id: "swift.bindings.type-annotations")?.sourceReferences
                == ["LanguageGuide/TheBasics.xhtml#Type-Annotations"]
        )
        #expect(
            catalog.lesson(id: "swift.bindings.identifier-naming")?.sourceReferences
                == ["LanguageGuide/TheBasics.xhtml#Naming-Constants-and-Variables"]
        )
        #expect(
            catalog.lesson(id: "swift.output.string-interpolation")?.sourceReferences.contains(
                "LanguageGuide/TheBasics.xhtml#Printing-Constants-and-Variables"
            ) == true
        )
        #expect(
            catalog.lesson(id: "swift.output.string-interpolation")?.sourceReferences.contains(
                "LanguageGuide/StringsAndCharacters.xhtml#String-Interpolation"
            ) == true
        )
        #expect(
            catalog.lesson(id: "swift.comments.single-line")?.sourceReferences
                == ["LanguageGuide/TheBasics.xhtml#Comments"]
        )
        #expect(catalog.lessons.allSatisfy { !$0.sourceReferences.isEmpty })
        #expect(
            catalog.lesson(id: "swift.logic.parentheses")?.sourceReferences
                == ["LanguageGuide/BasicOperators.xhtml#Explicit-Parentheses"]
        )
        #expect(catalog.lessons.last?.id == "swift.attributes.interface-builder")
        #expect(
            catalog.lessons.last?.sourceReferences.contains(
                "ReferenceManual/Attributes.xhtml#Declaration-Attributes-Used-by-Interface-Builder"
            ) == true
        )
    }

    @Test
    func caveatLessonsMapExactSourcesAndPlannedPositions() throws {
        let catalog = try bundledCatalog()
        let expectedSources = [
            "swift.strings.foundation-bridging":
                "LanguageGuide/StringsAndCharacters.xhtml#strings-and-characters",
            "swift.arrays.foundation-bridging":
                "LanguageGuide/CollectionTypes.xhtml#Arrays",
            "swift.sets.foundation-bridging":
                "LanguageGuide/CollectionTypes.xhtml#Sets",
            "swift.dictionaries.foundation-bridging":
                "LanguageGuide/CollectionTypes.xhtml#Dictionaries",
            "swift.initialization.observer-bypass":
                "LanguageGuide/Initialization.xhtml#Setting-Initial-Values-for-Stored-Properties",
            "swift.errors.nserror-interoperability":
                "LanguageGuide/ErrorHandling.xhtml#error-handling",
            "swift.errors.no-stack-unwinding":
                "LanguageGuide/ErrorHandling.xhtml#Handling-Errors",
            "swift.concurrency.thread-independence":
                "LanguageGuide/Concurrency.xhtml#concurrency",
            "swift.extensions.no-overrides":
                "LanguageGuide/Extensions.xhtml#extensions"
        ]

        for (lessonID, sourceReference) in expectedSources {
            #expect(catalog.lesson(id: lessonID)?.sourceReferences == [sourceReference])
        }

        #expect(
            catalog.levels.first { $0.id == "swift.text-and-unicode" }?.lessons.first?.id
                == "swift.strings.foundation-bridging"
        )
        #expect(
            catalog.levels.first { $0.id == "swift.collections" }?.lessons.map(\.id)
                .filter { $0.hasSuffix("foundation-bridging") }
                == [
                    "swift.arrays.foundation-bridging",
                    "swift.sets.foundation-bridging",
                    "swift.dictionaries.foundation-bridging"
                ]
        )
        #expect(
            catalog.levels.first { $0.id == "swift.initialization" }?.lessons[1].id
                == "swift.initialization.observer-bypass"
        )
        #expect(
            catalog.levels.first { $0.id == "swift.error-handling" }?.lessons
                .prefix(2).map(\.id)
                == [
                    "swift.errors.nserror-interoperability",
                    "swift.errors.no-stack-unwinding"
                ]
        )
        #expect(
            catalog.levels.first { $0.id == "swift.concurrency" }?.lessons.first?.id
                == "swift.concurrency.thread-independence"
        )
        #expect(
            catalog.levels.first { $0.id == "swift.extensions" }?.lessons.first?.id
                == "swift.extensions.no-overrides"
        )
    }

    @Test
    func malformedBundledContentFailsInsteadOfInventingLessons() {
        let repository = BundledLearningContentRepository(data: Data("{}".utf8))

        do {
            _ = try repository.loadCatalog()
            Issue.record("Expected malformed content to fail decoding")
        } catch is DecodingError {
            // Expected: invalid content is rejected.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func everyBundledLessonUnlocksAndCompletesInOrder() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository()
        let submitAnswer = SubmitLessonAnswerUseCase(
            contentRepository: content,
            progressRepository: progress
        )

        for (index, lesson) in catalog.lessons.enumerated() {
            let journey = try LoadLearningJourneyUseCase(
                contentRepository: content,
                progressRepository: progress
            ).execute()

            #expect(journey.isUnlocked(lessonID: lesson.id))

            let result = try submitAnswer.execute(
                lessonID: lesson.id,
                choiceID: lesson.correctChoiceID
            )

            #expect(result.isCorrect)
            #expect(progress.completedLessonIDs.count == index + 1)
        }
    }

    @Test
    func inMemoryContainerLoadsContentAndPersistsCompletion() throws {
        let container = try AppContainer(isStoredInMemoryOnly: true)
        let viewModel = container.learningJourneyViewModel

        viewModel.load()
        #expect(viewModel.journey?.completedLessonCount == 0)

        for (index, lesson) in try bundledCatalog().lessons.enumerated() {
            viewModel.selectChoice(lesson.correctChoiceID)
            viewModel.submit(lessonID: lesson.id)
            viewModel.load()

            #expect(viewModel.journey?.completedLessonCount == index + 1)
        }
    }

    @Test
    func achievementsDeriveFromJourneyProgressAndCatalog() throws {
        let catalog = try bundledCatalog()
        let calculator = CalculateAchievementsUseCase()

        let emptyAchievements = calculator.execute(
            journey: LearningJourney(catalog: catalog, completedLessonIDs: [])
        )
        #expect(
            emptyAchievements.first { $0.id == "achievement.first-lesson" }?.isEarned
                == false
        )
        #expect(
            emptyAchievements.first { $0.id == "achievement.source-complete" }?
                .totalRequirementCount == catalog.lessons.count
        )

        let firstLessonAchievements = calculator.execute(
            journey: LearningJourney(
                catalog: catalog,
                completedLessonIDs: [try #require(catalog.lessons.first).id]
            )
        )
        #expect(
            firstLessonAchievements.first { $0.id == "achievement.first-lesson" }?.isEarned
                == true
        )
        #expect(
            firstLessonAchievements.first { $0.id == "achievement.lessons.10" }?
                .completedRequirementCount == 1
        )

        let firstLevel = try #require(catalog.levels.first)
        let firstLevelAchievements = calculator.execute(
            journey: LearningJourney(
                catalog: catalog,
                completedLessonIDs: Set(firstLevel.lessons.map(\.id))
            )
        )
        #expect(
            firstLevelAchievements.first { $0.id == "achievement.first-level" }?.isEarned
                == true
        )
        #expect(
            firstLevelAchievements.first {
                $0.id == "achievement.level.\(firstLevel.id)"
            }?.isEarned == true
        )

        let completeAchievements = calculator.execute(
            journey: LearningJourney(
                catalog: catalog,
                completedLessonIDs: Set(catalog.lessons.map(\.id))
            )
        )
        #expect(
            completeAchievements.first { $0.id == "achievement.source-complete" }?.isEarned
                == true
        )
        #expect(
            completeAchievements.filter(\.isEarned).count == completeAchievements.count
        )
    }

    @Test
    func progressEventsDescribeOnlyNewLearningTransitions() throws {
        let catalog = try bundledCatalog()
        let firstLesson = try #require(catalog.lessons.first)
        let secondLesson = try #require(catalog.lessons.dropFirst().first)
        let calculator = CalculateLearningProgressEventsUseCase(
            calculateAchievements: CalculateAchievementsUseCase()
        )
        let before = LearningJourney(catalog: catalog, completedLessonIDs: [])
        let after = LearningJourney(
            catalog: catalog,
            completedLessonIDs: [firstLesson.id]
        )

        let events = calculator.execute(before: before, after: after)

        #expect(events.contains(.lessonCompleted(firstLesson.id)))
        #expect(events.contains(.lessonUnlocked(secondLesson.id)))
        #expect(
            events.contains { event in
                guard case let .achievementEarned(achievement) = event else {
                    return false
                }
                return achievement.id == "achievement.first-lesson"
            }
        )
        #expect(calculator.execute(before: after, after: after).isEmpty)
    }

    @Test
    func motionPolicyAlwaysHonorsSystemReduceMotion() {
        #expect(
            LearningMotionPolicy.shouldReduceMotion(
                systemReduceMotion: true,
                preference: .system
            )
        )
        #expect(
            LearningMotionPolicy.shouldReduceMotion(
                systemReduceMotion: false,
                preference: .reduced
            )
        )
        #expect(
            !LearningMotionPolicy.shouldReduceMotion(
                systemReduceMotion: false,
                preference: .system
            )
        )
    }

    @Test
    func loadProfileCombinesPreferencesProgressAndAchievements() throws {
        let catalog = try bundledCatalog()
        let firstLessonID = try #require(catalog.lessons.first).id
        let profile = LearnerProfile(
            displayName: "Ada",
            avatar: .terminal,
            appearance: .dark
        )
        let useCase = LoadLearnerProfileUseCase(
            contentRepository: InMemoryLearningContentRepository(catalog: catalog),
            progressRepository: InMemoryLearningProgressRepository(
                completedLessonIDs: [firstLessonID]
            ),
            profileRepository: InMemoryLearnerProfileRepository(profile: profile)
        )

        let snapshot = try useCase.execute()

        #expect(snapshot.profile == profile)
        #expect(snapshot.journey.completedLessonCount == 1)
        #expect(snapshot.completedLevelCount == 0)
        #expect(
            snapshot.achievements.first { $0.id == "achievement.first-lesson" }?.isEarned
                == true
        )
    }

    @Test
    func updateProfileNormalizesAndValidatesDisplayName() throws {
        let repository = InMemoryLearnerProfileRepository()
        let useCase = UpdateLearnerProfileUseCase(profileRepository: repository)

        let profile = try useCase.execute(
            displayName: "  Ada Lovelace  ",
            avatar: .book,
            appearance: .light,
            motionPreference: .reduced
        )

        #expect(profile.displayName == "Ada Lovelace")
        #expect(profile.motionPreference == .reduced)
        #expect(repository.profile == profile)
        #expect(throws: LearnerProfileError.emptyDisplayName) {
            try useCase.execute(
                displayName: "   ",
                avatar: .code,
                appearance: .system
            )
        }
        #expect(throws: LearnerProfileError.displayNameTooLong) {
            try useCase.execute(
                displayName: String(repeating: "a", count: 41),
                avatar: .code,
                appearance: .system
            )
        }
    }

    @Test
    func profileViewModelLoadsSavesAndExposesFailures() throws {
        let catalog = try bundledCatalog()
        let profileRepository = InMemoryLearnerProfileRepository()
        let viewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: profileRepository
        )

        viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.snapshot?.profile == .defaultProfile)

        viewModel.draftDisplayName = "Grace"
        viewModel.draftAvatar = .star
        viewModel.draftAppearance = .dark
        viewModel.draftMotionPreference = .reduced
        viewModel.save()

        #expect(viewModel.saveState == .saved)
        #expect(viewModel.snapshot?.profile.displayName == "Grace")
        #expect(viewModel.snapshot?.profile.avatar == .star)
        #expect(viewModel.snapshot?.profile.appearance == .dark)
        #expect(viewModel.snapshot?.profile.motionPreference == .reduced)

        let failingViewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: FailingLearnerProfileRepository()
        )
        failingViewModel.load()
        #expect(failingViewModel.loadState == .failed("Profile unavailable"))
        failingViewModel.save()
        #expect(failingViewModel.saveState == .failed("Profile unavailable"))
    }

    @Test
    func swiftDataProfileRepositoryPersistsAndMapsInvalidStoredPreferences() throws {
        let container = try AppContainer(isStoredInMemoryOnly: true)
        let repository = SwiftDataLearnerProfileRepository(
            modelContext: container.modelContainer.mainContext
        )

        #expect(try repository.loadProfile() == .defaultProfile)

        let profile = LearnerProfile(
            displayName: "Chris",
            avatar: .terminal,
            appearance: .dark,
            motionPreference: .reduced
        )
        try repository.saveProfile(profile)
        #expect(try repository.loadProfile() == profile)

        let record = try #require(
            container.modelContainer.mainContext.fetch(
                FetchDescriptor<LearnerProfileRecord>()
            ).first
        )
        record.avatarRawValue = "unknown-avatar"
        record.appearanceRawValue = "unknown-appearance"
        record.motionPreferenceRawValue = "unknown-motion"
        try container.modelContainer.mainContext.save()

        let mappedProfile = try repository.loadProfile()
        #expect(mappedProfile.avatar == .code)
        #expect(mappedProfile.appearance == .system)
        #expect(mappedProfile.motionPreference == .system)
    }

    private func makeViewModel(
        content: InMemoryLearningContentRepository,
        progress: any LearningProgressRepository
    ) -> LearningJourneyViewModel {
        LearningJourneyViewModel(
            loadJourney: LoadLearningJourneyUseCase(
                contentRepository: content,
                progressRepository: progress
            ),
            submitAnswer: SubmitLessonAnswerUseCase(
                contentRepository: content,
                progressRepository: progress
            ),
            calculateProgressEvents: CalculateLearningProgressEventsUseCase(
                calculateAchievements: CalculateAchievementsUseCase()
            )
        )
    }

    private func bundledCatalog() throws -> LearningCatalog {
        try BundledLearningContentRepository(
            bundle: Bundle(for: AppContainer.self)
        ).loadCatalog()
    }

    private func makeProfileViewModel(
        catalog: LearningCatalog,
        profileRepository: any LearnerProfileRepository
    ) -> LearnerProfileViewModel {
        LearnerProfileViewModel(
            loadProfile: LoadLearnerProfileUseCase(
                contentRepository: InMemoryLearningContentRepository(catalog: catalog),
                progressRepository: InMemoryLearningProgressRepository(),
                profileRepository: profileRepository
            ),
            updateProfile: UpdateLearnerProfileUseCase(
                profileRepository: profileRepository
            )
        )
    }
}

@MainActor
private final class InMemoryLearningContentRepository: LearningContentRepository {
    let catalog: LearningCatalog

    init(catalog: LearningCatalog) {
        self.catalog = catalog
    }

    func loadCatalog() -> LearningCatalog {
        catalog
    }
}

@MainActor
private final class InMemoryLearningProgressRepository: LearningProgressRepository {
    var completedLessonIDs: Set<String>

    init(completedLessonIDs: Set<String> = []) {
        self.completedLessonIDs = completedLessonIDs
    }

    func loadCompletedLessonIDs() -> Set<String> {
        completedLessonIDs
    }

    func markCompleted(lessonID: String) {
        completedLessonIDs.insert(lessonID)
    }
}

@MainActor
private final class FailingLearningProgressRepository: LearningProgressRepository {
    func loadCompletedLessonIDs() throws -> Set<String> {
        throw FixtureError.progressUnavailable
    }

    func markCompleted(lessonID: String) throws {
        throw FixtureError.progressUnavailable
    }
}

@MainActor
private final class InMemoryLearnerProfileRepository: LearnerProfileRepository {
    var profile: LearnerProfile

    init(profile: LearnerProfile = .defaultProfile) {
        self.profile = profile
    }

    func loadProfile() -> LearnerProfile {
        profile
    }

    func saveProfile(_ profile: LearnerProfile) {
        self.profile = profile
    }
}

@MainActor
private final class FailingLearnerProfileRepository: LearnerProfileRepository {
    func loadProfile() throws -> LearnerProfile {
        throw FixtureError.profileUnavailable
    }

    func saveProfile(_ profile: LearnerProfile) throws {
        throw FixtureError.profileUnavailable
    }
}

private enum FixtureError: LocalizedError {
    case progressUnavailable
    case profileUnavailable

    var errorDescription: String? {
        switch self {
        case .progressUnavailable:
            "Progress unavailable"
        case .profileUnavailable:
            "Profile unavailable"
        }
    }
}
