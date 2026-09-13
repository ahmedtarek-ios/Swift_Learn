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
    private let sourceDisclosure = LearningSourceDisclosure(
        sourceID: "swift-6.4-beta-fixture",
        editionTitle: "The Swift Programming Language — Swift 6.4 beta"
    )

    @Test
    func introMovesThroughFourStepsAndStartsLearning() {
        let viewModel = IntroViewModel(sourceDisclosure: sourceDisclosure)

        #expect(viewModel.isPresented)
        #expect(viewModel.currentStep == .welcome)
        #expect(viewModel.isFirstStep)

        viewModel.showNextStep()

        #expect(viewModel.currentStep == .practice)
        #expect(viewModel.isFirstStep == false)
        #expect(viewModel.isLastStep == false)

        viewModel.showNextStep()

        #expect(viewModel.currentStep == .progress)
        #expect(viewModel.isLastStep == false)

        viewModel.showNextStep()

        #expect(viewModel.currentStep == .source)
        #expect(viewModel.isLastStep)
        #expect(viewModel.sourceDisclosure == sourceDisclosure)

        viewModel.startLearning()

        #expect(viewModel.isPresented == false)
    }

    @Test
    func introBackNavigationStopsAtFirstStep() {
        let viewModel = IntroViewModel(
            currentStep: .source,
            sourceDisclosure: sourceDisclosure
        )

        viewModel.showPreviousStep()
        #expect(viewModel.currentStep == .progress)

        viewModel.showPreviousStep()
        #expect(viewModel.currentStep == .practice)

        viewModel.showPreviousStep()
        viewModel.showPreviousStep()

        #expect(viewModel.currentStep == .welcome)
        #expect(viewModel.isFirstStep)
    }

    @Test
    func introCanStartDismissedForDeterministicLaunches() {
        let viewModel = IntroViewModel(
            isPresented: false,
            sourceDisclosure: sourceDisclosure
        )

        #expect(viewModel.isPresented == false)
    }

    @Test
    func journeyReloadAtRootResetsNavigationAndAttemptState() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: ["swift.bindings.constants"]
        )
        let viewModel = makeViewModel(content: content, progress: progress)

        viewModel.load()
        viewModel.selectChoice("let")

        #expect(viewModel.navigationRevision == 0)
        #expect(viewModel.selectedChoiceID == "let")

        viewModel.reloadAtJourneyRoot()

        #expect(viewModel.navigationRevision == 1)
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.selectedChoiceID == nil)
        #expect(viewModel.attemptResult == nil)
        #expect(viewModel.journey?.completedLessonCount == 1)
    }

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
                choiceID: "message-hello"
            )
        }
    }

    @Test
    func outputPredictionCompletesUnlockedFourthLesson() throws {
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
            choiceID: "message-hello"
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
            viewModel.progressSummary
                == "1 of \(content.catalog.lessons.count) skills practiced"
        )
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
    func bundledActivitiesMigrateLegacyChoicesAndDecodeOutputPrediction() throws {
        let catalog = try bundledCatalog()
        let legacyLesson = try #require(catalog.lessons.first)
        let predictionLesson = try #require(
            catalog.lesson(id: "swift.output.string-interpolation")
        )

        #expect(legacyLesson.activity.kind == .missingCode)
        #expect(legacyLesson.activity.schemaVersion == 1)
        #expect(
            legacyLesson.code(selectedChoiceID: nil)
                == "___ dailyPracticeGoal = 20"
        )

        #expect(predictionLesson.activity.kind == .outputPrediction)
        #expect(predictionLesson.activity.schemaVersion == 1)
        #expect(predictionLesson.activity.prompt == "What does this code print?")
        #expect(
            predictionLesson.code(selectedChoiceID: "message-welcome")
                == "let welcome = \"Hello\"\nprint(\"Message: \\(welcome)\")"
        )
        #expect(predictionLesson.correctChoiceID == "message-hello")
        #expect(
            catalog.lessons.filter { $0.activity.kind == .outputPrediction }.count == 1
        )
        #expect(
            catalog.lessons.filter { $0.activity.kind == .missingCode }.count == 485
        )
    }

    @Test
    func activityFixtureUnlocksTheRepresentativeLessonOnlyThroughProgress() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            seedsActivityFixture: true
        )
        let viewModel = container.learningJourneyViewModel

        viewModel.load()

        let journey = try #require(viewModel.journey)
        let predictionLesson = try #require(
            journey.catalog.lessons.first {
                $0.activity.kind == .outputPrediction
            }
        )
        #expect(journey.completedLessonCount == 3)
        #expect(journey.isUnlocked(lessonID: predictionLesson.id))
        #expect(!journey.isCompleted(lessonID: predictionLesson.id))
    }

    @Test
    func unsupportedActivitySchemaFailsWithoutInventingFallbackBehavior() {
        let data = Data(
            """
            {
              "sourceID": "fixture",
              "editionTitle": "Fixture",
              "levels": [{
                "id": "level",
                "title": "Level",
                "summary": "Summary",
                "lessons": [{
                  "id": "lesson",
                  "title": "Lesson",
                  "objective": "Objective",
                  "instruction": "Instruction",
                  "activity": {
                    "schemaVersion": 2,
                    "type": "outputPrediction",
                    "prompt": "Predict",
                    "code": "print(1)",
                    "choices": [{"id": "one", "code": "1"}],
                    "correctChoiceID": "one"
                  },
                  "correctFeedback": "Correct",
                  "incorrectFeedback": "Incorrect",
                  "sourceTitle": "Source",
                  "sourceReferences": ["source#lesson"]
                }]
              }]
            }
            """.utf8
        )
        let repository = BundledLearningContentRepository(data: data)

        #expect(throws: LearningContentError.unsupportedActivitySchema(2)) {
            try repository.loadCatalog()
        }
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
    func achievementAccessibilityDescribesLockedAndEarnedProgress() {
        let definition = AchievementDefinition(
            id: "achievement.first-lesson",
            title: "First Lesson",
            summary: "Complete your first Swift lesson.",
            kind: .firstLesson
        )
        let locked = AchievementProgress(
            definition: definition,
            completedRequirementCount: 0,
            totalRequirementCount: 1
        )
        let earned = AchievementProgress(
            definition: definition,
            completedRequirementCount: 1,
            totalRequirementCount: 1
        )

        #expect(
            LearnerProfileViewModel.achievementAccessibilityLabel(for: locked)
                == "First Lesson, Locked"
        )
        #expect(
            LearnerProfileViewModel.achievementAccessibilityValue(for: locked)
                == "Locked, 0 of 1"
        )
        #expect(
            LearnerProfileViewModel.achievementAccessibilityLabel(for: earned)
                == "First Lesson, Earned"
        )
        #expect(
            LearnerProfileViewModel.achievementAccessibilityValue(for: earned)
                == "Earned, 1 of 1"
        )
    }

    @Test
    func recentActivityUsesValidatedEvidenceAndReturnsNewestFive() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let lesson = try #require(catalog.lessons.first)
        let skillID = SkillID(rawValue: lesson.id)
        let projectRepository = ContentLearningProjectRepository(
            contentRepository: content
        )
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content,
                projectRepository: projectRepository
            )
        )
        let activityIDs: [LearningActivityID] = [
            lesson.activityID,
            .review(skillID: skillID),
            .challenge(skillID: skillID),
            .project(
                projectID: ContentLearningProjectRepository.foundationsProjectID,
                skillID: skillID
            ),
            lesson.activityID,
            .review(skillID: skillID)
        ]
        let identifiers = try (1...7).map { value in
            try #require(
                UUID(
                    uuidString: String(
                        format: "00000000-0000-0000-0000-%012d",
                        value
                    )
                )
            )
        }
        let validAttempts = activityIDs.enumerated().map { index, activityID in
            LearningAttempt(
                id: identifiers[index],
                evidence: LearningEvidence(
                    lessonID: lesson.id,
                    skillID: skillID,
                    activityID: activityID,
                    outcome: index == 2 ? .incorrect : .correct,
                    errorCategory: index == 2 ? .incorrectChoice : nil
                ),
                recordedAt: Date(timeIntervalSince1970: TimeInterval(index + 1))
            )
        }
        let orphanedAttempt = LearningAttempt(
            id: identifiers[6],
            evidence: LearningEvidence(
                lessonID: "unknown.lesson",
                skillID: SkillID(rawValue: "unknown.skill"),
                activityID: LearningActivityID(rawValue: "unknown.activity"),
                outcome: .correct,
                errorCategory: nil
            ),
            recordedAt: Date(timeIntervalSince1970: 100)
        )
        let useCase = LoadRecentLearningActivityUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: InMemoryLearningAttemptRepository(
                attempts: validAttempts + [orphanedAttempt]
            )
        )

        let activities = try useCase.execute()

        #expect(activities.count == LoadRecentLearningActivityUseCase.maximumActivityCount)
        #expect(activities.map(\.recordedAt.timeIntervalSince1970) == [6, 5, 4, 3, 2])
        #expect(
            activities.map(\.kind)
                == [.review, .lesson, .guidedProject, .bossChallenge, .review]
        )
        #expect(activities.map(\.skillTitle) == Array(repeating: lesson.title, count: 5))
        #expect(activities.contains { $0.skillID.rawValue == "unknown.skill" } == false)
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
            avatar: .boy,
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
            avatar: .woman,
            appearance: .light,
            motionPreference: .reduced
        )

        #expect(profile.displayName == "Ada Lovelace")
        #expect(profile.motionPreference == .reduced)
        #expect(repository.profile == profile)
        #expect(throws: LearnerProfileError.emptyDisplayName) {
            try useCase.execute(
                displayName: "   ",
                avatar: .unknown,
                appearance: .system
            )
        }
        #expect(throws: LearnerProfileError.displayNameTooLong) {
            try useCase.execute(
                displayName: String(repeating: "a", count: 41),
                avatar: .unknown,
                appearance: .system
            )
        }
        #expect(throws: LearnerProfileError.missingCustomAvatarImage) {
            try useCase.execute(
                displayName: "Ada",
                avatar: .custom,
                appearance: .system
            )
        }

        let customImageData = Data([0x01, 0x02, 0x03])
        let customProfile = try useCase.execute(
            displayName: "Ada",
            avatar: .custom,
            customAvatarImageData: customImageData,
            appearance: .system
        )
        #expect(customProfile.customAvatarImageData == customImageData)
    }

    @Test
    func badgeShowcaseAcceptsOnlyEarnedAchievements() throws {
        let repository = InMemoryLearnerProfileRepository()
        let useCase = UpdateLearnerBadgeShowcaseUseCase(
            profileRepository: repository
        )
        let earned = AchievementProgress(
            definition: AchievementDefinition(
                id: "achievement.earned",
                title: "Earned",
                summary: "Earned fixture",
                kind: .firstLesson
            ),
            completedRequirementCount: 1,
            totalRequirementCount: 1
        )
        let locked = AchievementProgress(
            definition: AchievementDefinition(
                id: "achievement.locked",
                title: "Locked",
                summary: "Locked fixture",
                kind: .firstLevel
            ),
            completedRequirementCount: 0,
            totalRequirementCount: 1
        )

        let selected = try useCase.execute(
            achievementID: earned.id,
            achievements: [earned, locked]
        )
        #expect(selected.showcasedAchievementID == earned.id)
        #expect(repository.profile == selected)

        #expect(throws: LearnerProfileError.achievementNotEarned) {
            try useCase.execute(
                achievementID: locked.id,
                achievements: [earned, locked]
            )
        }
        #expect(repository.profile.showcasedAchievementID == earned.id)

        let cleared = try useCase.reconcile(achievements: [locked])
        #expect(cleared.showcasedAchievementID == nil)
    }

    @Test
    func profileViewModelPersistsAndReconcilesBadgeShowcase() throws {
        let catalog = try bundledCatalog()
        let firstLesson = try #require(catalog.lessons.first)
        let profileRepository = InMemoryLearnerProfileRepository()
        let progressRepository = InMemoryLearningProgressRepository(
            completedLessonIDs: [firstLesson.id]
        )
        let resetRepository = InMemoryLearningResetRepository {
            progressRepository.completedLessonIDs.removeAll()
        }
        let viewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: profileRepository,
            progressRepository: progressRepository,
            resetRepository: resetRepository
        )

        viewModel.load()
        let earned = try #require(
            viewModel.achievements.first { $0.id == "achievement.first-lesson" }
        )
        #expect(earned.isEarned)

        viewModel.toggleBadgeShowcase(earned)
        #expect(viewModel.badgeShowcaseState == .saved)
        #expect(viewModel.showcasedAchievement?.id == earned.id)
        #expect(profileRepository.profile.showcasedAchievementID == earned.id)

        viewModel.draftDisplayName = "Showcase Learner"
        viewModel.save()
        #expect(viewModel.snapshot?.profile.showcasedAchievementID == earned.id)

        viewModel.resetLearningProgress()
        #expect(viewModel.showcasedAchievement == nil)
        #expect(profileRepository.profile.showcasedAchievementID == nil)
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
        #expect(viewModel.masteryOverview?.snapshots.count == catalog.lessons.count)
        #expect(viewModel.masteryOverview?.masteredCount == 0)
        #expect(viewModel.recentActivityState == .loaded)
        #expect(viewModel.recentActivities.isEmpty)
        #expect(
            viewModel.recentActivityAccessibilityValue
                == "No Learning Activity Yet"
        )
        #expect(viewModel.experienceAchievementState == .loaded)
        #expect(viewModel.experienceAchievements.count == 2)
        #expect(
            viewModel.progressSummary
                == "0 of \(catalog.lessons.count) lessons completed"
        )

        viewModel.draftDisplayName = "Grace"
        viewModel.selectBuiltInAvatar(.girl)
        viewModel.draftAppearance = .dark
        viewModel.draftMotionPreference = .reduced
        viewModel.save()

        #expect(viewModel.saveState == .saved)
        #expect(viewModel.snapshot?.profile.displayName == "Grace")
        #expect(viewModel.snapshot?.profile.avatar == .girl)
        #expect(viewModel.snapshot?.profile.appearance == .dark)
        #expect(viewModel.snapshot?.profile.motionPreference == .reduced)

        let customImageData = Data([0xCA, 0xFE])
        viewModel.beginAvatarImport()
        #expect(viewModel.avatarImportState == .importing)
        viewModel.selectCustomAvatar(imageData: customImageData)
        #expect(viewModel.draftAvatar == .custom)
        #expect(viewModel.draftCustomAvatarImageData == customImageData)
        #expect(viewModel.avatarImportState == .idle)
        viewModel.save()
        #expect(viewModel.snapshot?.profile.avatar == .custom)
        #expect(viewModel.snapshot?.profile.customAvatarImageData == customImageData)

        viewModel.selectCustomAvatar(imageData: Data())
        #expect(
            viewModel.avatarImportState
                == .failed("The selected image could not be loaded.")
        )

        let failingViewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: FailingLearnerProfileRepository()
        )
        failingViewModel.load()
        #expect(failingViewModel.loadState == .failed("Profile unavailable"))
        failingViewModel.save()
        #expect(failingViewModel.saveState == .failed("Profile unavailable"))

        let recentFailureViewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: InMemoryLearnerProfileRepository(),
            recentAttemptRepository: FailingLearningAttemptRepository()
        )
        recentFailureViewModel.load()
        #expect(recentFailureViewModel.loadState == .loaded)
        #expect(
            recentFailureViewModel.recentActivityState
                == .failed("Attempts unavailable")
        )
        #expect(
            recentFailureViewModel.recentActivityAccessibilityValue
                == "Recent activity unavailable"
        )

        let achievementFailureViewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: InMemoryLearnerProfileRepository(),
            bossCompletionRepository: InMemoryBossChallengeCompletionRepository(
                error: FixtureError.completionUnavailable
            )
        )
        achievementFailureViewModel.load()
        #expect(achievementFailureViewModel.loadState == .loaded)
        #expect(
            achievementFailureViewModel.experienceAchievementState
                == .failed("Challenge completion unavailable")
        )
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
            avatar: .man,
            appearance: .dark,
            motionPreference: .reduced,
            showcasedAchievementID: "achievement.first-lesson"
        )
        try repository.saveProfile(profile)
        #expect(try repository.loadProfile() == profile)
        #expect(
            try container.modelContainer.mainContext.fetch(
                FetchDescriptor<LearnerBadgeShowcaseRecord>()
            ).first?.achievementID == "achievement.first-lesson"
        )

        let customImageData = Data([0x89, 0x50, 0x4E, 0x47])
        let customProfile = LearnerProfile(
            displayName: "Chris",
            avatar: .custom,
            customAvatarImageData: customImageData,
            appearance: .dark,
            motionPreference: .reduced,
            showcasedAchievementID: "achievement.first-lesson"
        )
        try repository.saveProfile(customProfile)
        #expect(try repository.loadProfile() == customProfile)
        #expect(
            try container.modelContainer.mainContext.fetch(
                FetchDescriptor<LearnerAvatarImageRecord>()
            ).first?.imageData == customImageData
        )

        let profileWithoutShowcase = LearnerProfile(
            displayName: profile.displayName,
            avatar: profile.avatar,
            appearance: profile.appearance,
            motionPreference: profile.motionPreference
        )
        try repository.saveProfile(profileWithoutShowcase)
        #expect(
            try container.modelContainer.mainContext.fetch(
                FetchDescriptor<LearnerAvatarImageRecord>()
            ).isEmpty
        )
        #expect(
            try container.modelContainer.mainContext.fetch(
                FetchDescriptor<LearnerBadgeShowcaseRecord>()
            ).isEmpty
        )

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
        #expect(mappedProfile.avatar == .unknown)
        #expect(mappedProfile.appearance == .system)
        #expect(mappedProfile.motionPreference == .system)
    }

    @Test
    func resetLearningProgressUseCaseDelegatesAndPropagatesFailure() throws {
        let repository = InMemoryLearningResetRepository()
        let useCase = ResetLearningProgressUseCase(resetRepository: repository)

        try useCase.execute()

        #expect(repository.resetCallCount == 1)

        let failingRepository = InMemoryLearningResetRepository(
            resetError: FixtureError.resetUnavailable
        )
        #expect(throws: FixtureError.resetUnavailable) {
            try ResetLearningProgressUseCase(
                resetRepository: failingRepository
            ).execute()
        }
    }

    @Test
    func swiftDataLearningResetClearsLearningButPreservesProfile() throws {
        let container = try AppContainer(isStoredInMemoryOnly: true)
        let context = container.modelContainer.mainContext
        let profileRepository = SwiftDataLearnerProfileRepository(
            modelContext: context
        )
        let customImageData = Data([0x89, 0x50, 0x4E, 0x47])
        let attemptID = try #require(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let profile = LearnerProfile(
            displayName: "Grace",
            avatar: .custom,
            customAvatarImageData: customImageData,
            appearance: .dark,
            motionPreference: .reduced
        )
        try profileRepository.saveProfile(profile)
        context.insert(
            LessonProgressRecord(
                lessonID: "swift.bindings.constants",
                completedAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        context.insert(
            LearningAttemptRecord(
                id: attemptID,
                lessonID: "swift.bindings.constants",
                skillID: "swift.bindings.constants",
                activityID: "swift.bindings.constants",
                outcomeRawValue: AttemptOutcome.incorrect.rawValue,
                errorCategoryRawValue: LearningErrorCategory.incorrectChoice.rawValue,
                recordedAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        context.insert(
            LearningProjectSubmissionRecord(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                projectID: ContentLearningProjectRepository.foundationsProjectID,
                validationResultsData: try JSONEncoder().encode(
                    [LearningProjectValidationResult]()
                ),
                submittedAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        context.insert(
            BossChallengeCompletionRecord(
                challengeID: "boss.level-1",
                levelID: "level-1",
                completedAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        try context.save()

        try SwiftDataLearningResetRepository(
            modelContext: context,
            syncGeneration: SwiftDataLearningSyncRepository(modelContext: context)
        ).resetLearningProgress()

        #expect(try context.fetch(FetchDescriptor<LessonProgressRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<LearningAttemptRecord>()).isEmpty)
        #expect(
            try context.fetch(FetchDescriptor<LearningProjectSubmissionRecord>()).isEmpty
        )
        #expect(
            try context.fetch(FetchDescriptor<BossChallengeCompletionRecord>()).isEmpty
        )
        #expect(
            try SwiftDataLearningSyncRepository(
                modelContext: context
            ).loadSnapshot().resetGeneration == 1
        )
        #expect(try profileRepository.loadProfile() == profile)
        #expect(
            try context.fetch(FetchDescriptor<LearnerAvatarImageRecord>())
                .first?.imageData == customImageData
        )
    }

    @Test
    func profileViewModelResetsLearningAndKeepsProfile() throws {
        let catalog = try bundledCatalog()
        let firstLesson = try #require(catalog.lessons.first)
        let progressRepository = InMemoryLearningProgressRepository(
            completedLessonIDs: [firstLesson.id]
        )
        let attemptRepository = InMemoryLearningAttemptRepository()
        let attemptID = try #require(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        attemptRepository.record(
            LearningAttempt(
                id: attemptID,
                evidence: LearningEvidence(
                    lessonID: firstLesson.id,
                    skillID: SkillID(rawValue: firstLesson.id),
                    activityID: firstLesson.activityID,
                    outcome: .incorrect,
                    errorCategory: .incorrectChoice
                ),
                recordedAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        let profile = LearnerProfile(
            displayName: "Grace",
            avatar: .girl,
            appearance: .dark,
            motionPreference: .reduced
        )
        let firstLevel = try #require(catalog.levels.first)
        let bossCompletionRepository = InMemoryBossChallengeCompletionRepository(
            completions: [
                BossChallengeCompletion(
                    challengeID: "boss.\(firstLevel.id)",
                    levelID: firstLevel.id,
                    completedAt: Date(timeIntervalSince1970: 1_000)
                )
            ]
        )
        let resetRepository = InMemoryLearningResetRepository {
            progressRepository.completedLessonIDs.removeAll()
            attemptRepository.removeAll()
            bossCompletionRepository.removeAll()
        }
        let viewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: InMemoryLearnerProfileRepository(profile: profile),
            progressRepository: progressRepository,
            attemptRepository: attemptRepository,
            bossCompletionRepository: bossCompletionRepository,
            resetRepository: resetRepository
        )

        viewModel.load()
        #expect(viewModel.snapshot?.journey.completedLessonCount == 1)
        #expect(viewModel.masteryOverview?.reviewDueCount == 1)
        #expect(viewModel.recentActivities.count == 1)
        #expect(
            viewModel.experienceAchievements.first {
                $0.id == "achievement.boss.\(firstLevel.id)"
            }?.isEarned == true
        )

        viewModel.resetLearningProgress()

        #expect(viewModel.resetState == .reset)
        #expect(viewModel.resetRevision == 1)
        #expect(viewModel.snapshot?.profile == profile)
        #expect(viewModel.snapshot?.journey.completedLessonCount == 0)
        #expect(viewModel.masteryOverview?.reviewDueCount == 0)
        #expect(viewModel.recentActivityState == .loaded)
        #expect(viewModel.recentActivities.isEmpty)
        #expect(
            viewModel.experienceAchievements.first {
                $0.id == "achievement.boss.\(firstLevel.id)"
            }?.isEarned == false
        )
        #expect(resetRepository.resetCallCount == 1)

        let failingViewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: InMemoryLearnerProfileRepository(profile: profile),
            resetRepository: InMemoryLearningResetRepository(
                resetError: FixtureError.resetUnavailable
            )
        )
        failingViewModel.resetLearningProgress()
        #expect(failingViewModel.resetState == .failed("Reset unavailable"))
        #expect(failingViewModel.resetRevision == 0)
    }

    @Test
    func bossChallengeUnlocksAfterItsLevelAndReusesCanonicalSkills() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository()
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        )
        let loadChallenge = LoadBossChallengeUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: loadSkills
        )

        let locked = try loadChallenge.execute(levelID: level.id)

        #expect(!locked.isUnlocked)
        #expect(locked.completedRequirementCount == 0)
        #expect(locked.totalRequirementCount == level.lessons.count)
        #expect(locked.challenge.items.map(\.id) == level.lessons.prefix(2).map(\.id))

        for lesson in level.lessons {
            progress.markCompleted(lessonID: lesson.id)
        }
        let unlocked = try loadChallenge.execute(levelID: level.id)
        let canonicalSkills = try loadSkills.execute()

        #expect(unlocked.isUnlocked)
        #expect(unlocked.challenge.items.count == 2)
        for item in unlocked.challenge.items {
            let skill = try #require(
                canonicalSkills.first(where: { $0.id == item.skillID })
            )
            #expect(skill.lessonIDs.contains(item.lesson.id))
            #expect(skill.activityIDs.contains(.challenge(skillID: item.skillID)))
        }
    }

    @Test
    func bossChallengeRecordsEvidenceWithoutDuplicatingLessonProgress() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let completedLessonIDs = Set(level.lessons.map(\.id))
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: completedLessonIDs
        )
        let attempts = InMemoryLearningAttemptRepository()
        let clock = FixedLearningClock(now: Date(timeIntervalSince1970: 1_000))
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        )
        let loadChallenge = LoadBossChallengeUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: loadSkills
        )
        let challenge = try loadChallenge.execute(levelID: level.id).challenge
        let recordAttempt = RecordLearningAttemptUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: attempts,
            clock: clock,
            idGenerator: SystemLearningAttemptIDGenerator()
        )
        let submit = SubmitBossChallengeAnswerUseCase(
            loadChallenge: loadChallenge,
            recordAttempt: recordAttempt
        )
        let first = try #require(challenge.items.first)
        let second = try #require(challenge.items.dropFirst().first)
        let incorrectChoiceID = try #require(
            second.lesson.choices.first { $0.id != second.lesson.correctChoiceID }?.id
        )

        let correct = try submit.execute(
            levelID: level.id,
            itemID: first.id,
            choiceID: first.lesson.correctChoiceID
        )
        let incorrect = try submit.execute(
            levelID: level.id,
            itemID: second.id,
            choiceID: incorrectChoiceID
        )

        #expect(correct.isCorrect)
        #expect(!incorrect.isCorrect)
        #expect(progress.completedLessonIDs == completedLessonIDs)
        #expect(attempts.attempts.count == 2)
        #expect(attempts.attempts.map(\.evidence.outcome) == [.correct, .incorrect])
        #expect(
            attempts.attempts.allSatisfy {
                $0.evidence.activityID.difficulty == .challenge
            }
        )
        #expect(attempts.attempts.last?.evidence.errorCategory == .incorrectChoice)

        let mistakes = try LoadMistakeNotebookUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: attempts
        ).execute()
        #expect(mistakes.map(\.skillID) == [second.skillID])

        let mastery = try LoadMasteryOverviewUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: attempts,
            clock: clock
        ).execute()
        #expect(
            mastery.snapshots.first(where: { $0.id == first.skillID })?
                .correctAttemptCount == 1
        )
    }

    @Test
    func bossChallengeViewModelCompletesTwoSkillSession() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: Set(level.lessons.map(\.id))
        )
        let attempts = InMemoryLearningAttemptRepository()
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        )
        let loadChallenge = LoadBossChallengeUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: loadSkills
        )
        let completions = InMemoryBossChallengeCompletionRepository()
        let viewModel = BossChallengeViewModel(
            levelID: level.id,
            loadChallenge: loadChallenge,
            submitAnswer: SubmitBossChallengeAnswerUseCase(
                loadChallenge: loadChallenge,
                recordAttempt: RecordLearningAttemptUseCase(
                    loadCanonicalSkills: loadSkills,
                    attemptRepository: attempts,
                    clock: FixedLearningClock(now: Date(timeIntervalSince1970: 1_000)),
                    idGenerator: SystemLearningAttemptIDGenerator()
                )
            ),
            completeChallenge: CompleteBossChallengeUseCase(
                loadChallenge: loadChallenge,
                completionRepository: completions,
                clock: FixedLearningClock(now: Date(timeIntervalSince1970: 1_000))
            )
        )

        viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.availability?.isUnlocked == true)

        let first = try #require(viewModel.currentItem)
        viewModel.selectChoice(first.lesson.correctChoiceID)
        viewModel.submitCurrentAnswer()
        #expect(viewModel.currentItemIndex == 1)
        #expect(viewModel.attemptRevision == 1)
        #expect(viewModel.selectedChoiceID == nil)

        let second = try #require(viewModel.currentItem)
        #expect(second.id != first.id)
        #expect(viewModel.stepSummary == "Challenge 2 of 2")
        viewModel.submitCurrentAnswer()
        #expect(viewModel.currentItem?.id == second.id)
        #expect(viewModel.attemptRevision == 1)
        #expect(attempts.attempts.count == 1)
        viewModel.selectChoice(second.lesson.correctChoiceID)
        viewModel.submitCurrentAnswer()

        #expect(viewModel.result?.isPassed == true)
        #expect(viewModel.result?.correctAnswerCount == 2)
        #expect(viewModel.attemptRevision == 2)
        #expect(attempts.attempts.count == 2)
        #expect(completions.completions.map(\.challengeID) == ["boss.\(level.id)"])
        #expect(viewModel.completionSaveError == nil)
    }

    @Test
    func bossCompletionRequiresWholePassedSessionAndIsIdempotent() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: Set(level.lessons.map(\.id))
        )
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        )
        let loadChallenge = LoadBossChallengeUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: loadSkills
        )
        let challenge = try loadChallenge.execute(levelID: level.id).challenge
        let repository = InMemoryBossChallengeCompletionRepository()
        let useCase = CompleteBossChallengeUseCase(
            loadChallenge: loadChallenge,
            completionRepository: repository,
            clock: FixedLearningClock(now: Date(timeIntervalSince1970: 4_000))
        )
        let correctAnswers = challenge.items.map {
            BossChallengeAnswerResult(
                itemID: $0.id,
                isCorrect: true,
                feedback: "Correct"
            )
        }

        #expect(throws: BossChallengeDomainError.incompleteSession) {
            try useCase.execute(
                levelID: level.id,
                answers: Array(correctAnswers.dropLast())
            )
        }

        let duplicatedAnswer = try #require(correctAnswers.first)
        #expect(
            throws: BossChallengeDomainError.duplicateAnswer(
                duplicatedAnswer.itemID
            )
        ) {
            try useCase.execute(
                levelID: level.id,
                answers: correctAnswers + [duplicatedAnswer]
            )
        }

        var failedAnswers = correctAnswers
        let firstAnswer = try #require(failedAnswers.first)
        failedAnswers[0] = BossChallengeAnswerResult(
            itemID: firstAnswer.itemID,
            isCorrect: false,
            feedback: "Needs review"
        )
        #expect(try useCase.execute(levelID: level.id, answers: failedAnswers).isPassed == false)
        #expect(repository.completions.isEmpty)

        #expect(try useCase.execute(levelID: level.id, answers: correctAnswers).isPassed)
        #expect(try useCase.execute(levelID: level.id, answers: correctAnswers).isPassed)
        #expect(repository.completions.count == 1)
        #expect(repository.completions.first?.challengeID == challenge.id)
    }

    @Test
    func bossViewModelKeepsResultAndRetriesCompletionPersistence() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: Set(level.lessons.map(\.id))
        )
        let attempts = InMemoryLearningAttemptRepository()
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        )
        let loadChallenge = LoadBossChallengeUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: loadSkills
        )
        let completions = InMemoryBossChallengeCompletionRepository(
            error: FixtureError.completionUnavailable
        )
        let clock = FixedLearningClock(now: Date(timeIntervalSince1970: 5_000))
        let viewModel = BossChallengeViewModel(
            levelID: level.id,
            loadChallenge: loadChallenge,
            submitAnswer: SubmitBossChallengeAnswerUseCase(
                loadChallenge: loadChallenge,
                recordAttempt: RecordLearningAttemptUseCase(
                    loadCanonicalSkills: loadSkills,
                    attemptRepository: attempts,
                    clock: clock,
                    idGenerator: SystemLearningAttemptIDGenerator()
                )
            ),
            completeChallenge: CompleteBossChallengeUseCase(
                loadChallenge: loadChallenge,
                completionRepository: completions,
                clock: clock
            )
        )

        viewModel.load()
        for item in try #require(viewModel.availability?.challenge.items) {
            viewModel.selectChoice(item.lesson.correctChoiceID)
            viewModel.submitCurrentAnswer()
        }

        #expect(viewModel.result?.isPassed == true)
        #expect(viewModel.completionSaveError == "Challenge completion unavailable")
        #expect(completions.completions.isEmpty)

        completions.error = nil
        viewModel.retryCompletionSave()

        #expect(viewModel.completionSaveError == nil)
        #expect(completions.completions.count == 1)
    }

    @Test
    func experienceAchievementsRemainEarnedAfterLaterFailures() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: Set(level.lessons.map(\.id))
        )
        let projects = ContentLearningProjectRepository(contentRepository: content)
        let project = try #require(projects.loadProjects().first)
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content,
                projectRepository: projects
            )
        )
        let loadChallenge = LoadBossChallengeUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: loadSkills
        )
        let challenge = try loadChallenge.execute(levelID: level.id).challenge
        let bossCompletions = InMemoryBossChallengeCompletionRepository(
            completions: [
                BossChallengeCompletion(
                    challengeID: challenge.id,
                    levelID: level.id,
                    completedAt: Date(timeIntervalSince1970: 1_000)
                )
            ]
        )
        let passedResults = project.requirements.map { requirement in
            LearningProjectValidationResult(
                requirementID: requirement.id,
                lessonID: requirement.lesson.id,
                skillID: requirement.skillID,
                selectedChoiceID: requirement.lesson.correctChoiceID,
                outcome: .correct,
                feedback: requirement.lesson.correctFeedback
            )
        }
        var failedResults = passedResults
        let firstResult = try #require(failedResults.first)
        failedResults[0] = LearningProjectValidationResult(
            requirementID: firstResult.requirementID,
            lessonID: firstResult.lessonID,
            skillID: firstResult.skillID,
            selectedChoiceID: "incorrect",
            outcome: .incorrect,
            feedback: "Needs review"
        )
        let submissions = InMemoryLearningProjectSubmissionRepository(
            submissions: [
                LearningProjectSubmission(
                    id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!,
                    projectID: project.id,
                    results: passedResults,
                    submittedAt: Date(timeIntervalSince1970: 1_000)
                ),
                LearningProjectSubmission(
                    id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!,
                    projectID: project.id,
                    results: failedResults,
                    submittedAt: Date(timeIntervalSince1970: 2_000)
                )
            ]
        )

        let achievements = try LoadExperienceAchievementsUseCase(
            bossLevelIDs: [level.id],
            loadBossChallenge: loadChallenge,
            bossCompletionRepository: bossCompletions,
            projectRepository: projects,
            projectSubmissionRepository: submissions
        ).execute()

        #expect(
            achievements.first { $0.id == "achievement.\(challenge.id)" }?.isEarned
                == true
        )
        #expect(
            achievements.first { $0.id == "achievement.project.\(project.id)" }?.isEarned
                == true
        )
        #expect(submissions.loadLatestSubmission(projectID: project.id)?.isPassed == false)
    }

    @Test
    func guidedProjectUnlocksAfterThreePrerequisitesAndMapsCanonicalEvidence() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let projects = ContentLearningProjectRepository(contentRepository: content)
        let project = try #require(projects.loadProjects().first)
        let progress = InMemoryLearningProgressRepository()
        let submissions = InMemoryLearningProjectSubmissionRepository()
        let loadProject = LoadLearningProjectUseCase(
            projectRepository: projects,
            progressRepository: progress,
            submissionRepository: submissions
        )

        let locked = try loadProject.execute(projectID: project.id)
        #expect(!locked.isUnlocked)
        #expect(locked.completedRequirementCount == 0)
        #expect(locked.totalRequirementCount == 3)

        for requirement in project.requirements {
            progress.markCompleted(lessonID: requirement.lesson.id)
        }
        let unlocked = try loadProject.execute(projectID: project.id)
        let skills = try LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content,
                projectRepository: projects
            )
        ).execute()

        #expect(unlocked.isUnlocked)
        #expect(unlocked.completedRequirementCount == 3)
        for requirement in project.requirements {
            let skill = try #require(skills.first { $0.id == requirement.skillID })
            #expect(
                skill.activityIDs.contains(
                    .project(projectID: project.id, skillID: requirement.skillID)
                )
            )
        }
    }

    @Test
    func guidedProjectPersistsValidationAndCanonicalAttemptsWithoutLessonProgress() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let projects = ContentLearningProjectRepository(contentRepository: content)
        let project = try #require(projects.loadProjects().first)
        let completedLessonIDs = Set(project.requirements.map(\.lesson.id))
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: completedLessonIDs
        )
        let attempts = InMemoryLearningAttemptRepository()
        let submissions = InMemoryLearningProjectSubmissionRepository(
            attemptRepository: attempts
        )
        let clock = FixedLearningClock(now: Date(timeIntervalSince1970: 2_000))
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content,
                projectRepository: projects
            )
        )
        let loadProject = LoadLearningProjectUseCase(
            projectRepository: projects,
            progressRepository: progress,
            submissionRepository: submissions
        )
        let incorrectRequirement = try #require(project.requirements.dropFirst().first)
        let incorrectChoice = try #require(
            incorrectRequirement.lesson.choices.first {
                $0.id != incorrectRequirement.lesson.correctChoiceID
            }
        )
        let responses = project.requirements.map { requirement in
            LearningProjectResponse(
                requirementID: requirement.id,
                choiceID: requirement.id == incorrectRequirement.id
                    ? incorrectChoice.id
                    : requirement.lesson.correctChoiceID
            )
        }

        let submission = try SubmitLearningProjectUseCase(
            loadProject: loadProject,
            loadCanonicalSkills: loadSkills,
            submissionRepository: submissions,
            clock: clock,
            attemptIDGenerator: SystemLearningAttemptIDGenerator(),
            submissionIDGenerator: FixedLearningProjectSubmissionIDGenerator()
        ).execute(projectID: project.id, responses: responses)

        #expect(!submission.isPassed)
        #expect(submission.correctRequirementCount == 2)
        #expect(submissions.submissions == [submission])
        #expect(attempts.attempts.count == 3)
        #expect(progress.completedLessonIDs == completedLessonIDs)
        #expect(attempts.attempts.allSatisfy { $0.evidence.activityID.difficulty == .challenge })
        #expect(
            attempts.attempts.first {
                $0.evidence.skillID == incorrectRequirement.skillID
            }?.evidence.errorCategory == .incorrectChoice
        )

        let mistakes = try LoadMistakeNotebookUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: attempts
        ).execute()
        #expect(mistakes.map(\.skillID) == [incorrectRequirement.skillID])
        #expect(
            try loadProject.execute(projectID: project.id).latestSubmission == submission
        )
    }

    @Test
    func guidedProjectViewModelSubmitsThreeResponsesAsOneRevision() throws {
        let catalog = try bundledCatalog()
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let projects = ContentLearningProjectRepository(contentRepository: content)
        let project = try #require(projects.loadProjects().first)
        let progress = InMemoryLearningProgressRepository(
            completedLessonIDs: Set(project.requirements.map(\.lesson.id))
        )
        let attempts = InMemoryLearningAttemptRepository()
        let submissions = InMemoryLearningProjectSubmissionRepository(
            attemptRepository: attempts
        )
        let loadProject = LoadLearningProjectUseCase(
            projectRepository: projects,
            progressRepository: progress,
            submissionRepository: submissions
        )
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content,
                projectRepository: projects
            )
        )
        let viewModel = LearningProjectViewModel(
            projectID: project.id,
            loadProject: loadProject,
            submitProject: SubmitLearningProjectUseCase(
                loadProject: loadProject,
                loadCanonicalSkills: loadSkills,
                submissionRepository: submissions,
                clock: FixedLearningClock(now: Date(timeIntervalSince1970: 3_000)),
                attemptIDGenerator: SystemLearningAttemptIDGenerator(),
                submissionIDGenerator: FixedLearningProjectSubmissionIDGenerator()
            )
        )

        viewModel.load()
        viewModel.startSession()
        #expect(viewModel.availability?.isUnlocked == true)

        for (index, requirement) in project.requirements.enumerated() {
            #expect(viewModel.currentRequirement?.id == requirement.id)
            #expect(viewModel.selectedChoiceID == nil)
            #expect(viewModel.responses.count == index)
            viewModel.continueProject()
            #expect(viewModel.currentRequirement?.id == requirement.id)
            #expect(viewModel.responses.count == index)
            viewModel.selectChoice(requirement.lesson.correctChoiceID)
            viewModel.continueProject()
            if index < project.requirements.count - 1 {
                #expect(viewModel.currentRequirementIndex == index + 1)
                #expect(viewModel.attemptRevision == 0)
            }
        }

        #expect(viewModel.submission?.isPassed == true)
        #expect(viewModel.attemptRevision == 1)
        #expect(attempts.attempts.count == 3)
        #expect(submissions.submissions.count == 1)
    }

    private func makeViewModel(
        content: InMemoryLearningContentRepository,
        progress: any LearningProgressRepository
    ) -> LearningJourneyViewModel {
        let loadCanonicalSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        )
        return LearningJourneyViewModel(
            loadJourney: LoadLearningJourneyUseCase(
                contentRepository: content,
                progressRepository: progress
            ),
            submitAnswer: SubmitLessonAnswerUseCase(
                contentRepository: content,
                progressRepository: progress
            ),
            recordAttempt: RecordLearningAttemptUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: InMemoryLearningAttemptRepository(),
                clock: FixedLearningClock(now: Date(timeIntervalSince1970: 1_000)),
                idGenerator: SystemLearningAttemptIDGenerator()
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
        profileRepository: any LearnerProfileRepository,
        progressRepository: InMemoryLearningProgressRepository = .init(),
        attemptRepository: InMemoryLearningAttemptRepository = .init(),
        recentAttemptRepository: (any LearningAttemptRepository)? = nil,
        bossCompletionRepository: any BossChallengeCompletionRepository
            = InMemoryBossChallengeCompletionRepository(),
        projectSubmissionRepository: InMemoryLearningProjectSubmissionRepository = .init(),
        resetRepository: any LearningResetRepository = InMemoryLearningResetRepository()
    ) -> LearnerProfileViewModel {
        let contentRepository = InMemoryLearningContentRepository(catalog: catalog)
        let projectRepository = ContentLearningProjectRepository(
            contentRepository: contentRepository
        )
        let loadCanonicalSkills = LoadCanonicalSkillsUseCase(
            contentRepository: contentRepository,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: contentRepository,
                projectRepository: projectRepository
            )
        )
        let loadBossChallenge = LoadBossChallengeUseCase(
            contentRepository: contentRepository,
            progressRepository: progressRepository,
            loadCanonicalSkills: loadCanonicalSkills
        )
        return LearnerProfileViewModel(
            loadProfile: LoadLearnerProfileUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository,
                profileRepository: profileRepository
            ),
            loadMasteryOverview: LoadMasteryOverviewUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attemptRepository,
                clock: FixedLearningClock(now: Date(timeIntervalSince1970: 1_000))
            ),
            loadRecentActivity: LoadRecentLearningActivityUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: recentAttemptRepository ?? attemptRepository
            ),
            loadExperienceAchievements: LoadExperienceAchievementsUseCase(
                bossLevelIDs: catalog.levels.first.map { [$0.id] } ?? [],
                loadBossChallenge: loadBossChallenge,
                bossCompletionRepository: bossCompletionRepository,
                projectRepository: projectRepository,
                projectSubmissionRepository: projectSubmissionRepository
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
private final class InMemoryLearningAttemptRepository: LearningAttemptRepository {
    private(set) var attempts: [LearningAttempt] = []

    init(attempts: [LearningAttempt] = []) {
        self.attempts = attempts
    }

    func record(_ attempt: LearningAttempt) {
        attempts.append(attempt)
    }

    func loadAttempts(skillID: SkillID) -> [LearningAttempt] {
        attempts.filter { $0.evidence.skillID == skillID }
    }

    func loadAllAttempts() -> [LearningAttempt] {
        attempts
    }

    func removeAll() {
        attempts.removeAll()
    }
}

@MainActor
private final class FailingLearningAttemptRepository: LearningAttemptRepository {
    func record(_ attempt: LearningAttempt) throws {
        throw FixtureError.attemptsUnavailable
    }

    func loadAttempts(skillID: SkillID) throws -> [LearningAttempt] {
        throw FixtureError.attemptsUnavailable
    }

    func loadAllAttempts() throws -> [LearningAttempt] {
        throw FixtureError.attemptsUnavailable
    }
}

@MainActor
private final class InMemoryLearningProjectSubmissionRepository:
    LearningProjectSubmissionRepository {
    private(set) var submissions: [LearningProjectSubmission] = []
    private let attemptRepository: InMemoryLearningAttemptRepository?

    init(
        submissions: [LearningProjectSubmission] = [],
        attemptRepository: InMemoryLearningAttemptRepository? = nil
    ) {
        self.submissions = submissions
        self.attemptRepository = attemptRepository
    }

    func record(
        _ submission: LearningProjectSubmission,
        attempts: [LearningAttempt]
    ) {
        submissions.append(submission)
        for attempt in attempts {
            attemptRepository?.record(attempt)
        }
    }

    func loadLatestSubmission(
        projectID: String
    ) -> LearningProjectSubmission? {
        loadSubmissions(projectID: projectID).first
    }

    func loadSubmissions(
        projectID: String
    ) -> [LearningProjectSubmission] {
        submissions
            .filter { $0.projectID == projectID }
            .sorted { $0.submittedAt > $1.submittedAt }
    }

    func removeAll() {
        submissions.removeAll()
    }
}

@MainActor
private final class InMemoryBossChallengeCompletionRepository:
    BossChallengeCompletionRepository {
    private(set) var completions: [BossChallengeCompletion]
    var error: (any Error)?

    init(
        completions: [BossChallengeCompletion] = [],
        error: (any Error)? = nil
    ) {
        self.completions = completions
        self.error = error
    }

    func record(_ completion: BossChallengeCompletion) throws {
        if let error { throw error }
        guard completions.contains(where: { $0.challengeID == completion.challengeID }) == false else {
            return
        }
        completions.append(completion)
    }

    func loadCompletions() throws -> [BossChallengeCompletion] {
        if let error { throw error }
        return completions
    }

    func removeAll() {
        completions.removeAll()
    }
}

@MainActor
private struct FixedLearningProjectSubmissionIDGenerator:
    LearningProjectSubmissionIDGenerating {
    func next() -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
    }
}

@MainActor
private final class InMemoryLearningResetRepository: LearningResetRepository {
    private let resetError: (any Error)?
    private let onReset: @MainActor () throws -> Void
    private(set) var resetCallCount = 0

    init(
        resetError: (any Error)? = nil,
        onReset: @escaping @MainActor () throws -> Void = {}
    ) {
        self.resetError = resetError
        self.onReset = onReset
    }

    func resetLearningProgress() throws {
        resetCallCount += 1
        if let resetError {
            throw resetError
        }
        try onReset()
    }
}

@MainActor
private struct FixedLearningClock: LearningClock {
    let now: Date
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

private enum FixtureError: LocalizedError, Equatable {
    case progressUnavailable
    case profileUnavailable
    case resetUnavailable
    case attemptsUnavailable
    case completionUnavailable

    var errorDescription: String? {
        switch self {
        case .progressUnavailable:
            "Progress unavailable"
        case .profileUnavailable:
            "Profile unavailable"
        case .resetUnavailable:
            "Reset unavailable"
        case .attemptsUnavailable:
            "Attempts unavailable"
        case .completionUnavailable:
            "Challenge completion unavailable"
        }
    }
}
