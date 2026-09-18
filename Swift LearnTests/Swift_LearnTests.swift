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
        #expect(viewModel.currentAchievementHeadline == "Achievement Unlocked")
        viewModel.dismissCurrentAchievement()
        #expect(viewModel.currentAchievement == nil)
        #expect(
            viewModel.nextLesson(after: "swift.bindings.constants")?.id
                == "swift.bindings.type-annotations"
        )
    }

    @Test
    func completingFirstLevelShowsOneLevelCelebration() throws {
        let catalog = try bundledCatalog()
        let level = try #require(catalog.levels.first)
        let finalLesson = try #require(level.lessons.last)
        let completed = Set(level.lessons.dropLast().map(\.id))
        let progress = InMemoryLearningProgressRepository(completedLessonIDs: completed)
        let viewModel = makeViewModel(
            content: InMemoryLearningContentRepository(catalog: catalog),
            progress: progress
        )

        viewModel.load()
        viewModel.selectChoice(try #require(finalLesson.correctChoiceID))
        viewModel.submit(lessonID: finalLesson.id)

        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.progressEvents.contains(.levelCompleted(level.id)))
        #expect(viewModel.currentAchievement?.id == "achievement.level.\(level.id)")
        #expect(viewModel.currentAchievementHeadline == "Level Complete")

        viewModel.dismissCurrentAchievement()
        #expect(viewModel.currentAchievement == nil)
        #expect(viewModel.currentAchievementHeadline == "Achievement Unlocked")
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
    func bundledActivitiesMigrateLegacyChoicesAndDecodeTypedActivities() throws {
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
        let orderingLesson = try #require(catalog.lesson(id: "swift.comments.multiline"))
        guard case let .codeOrdering(ordering) = orderingLesson.activity else {
            Issue.record("Expected a code-ordering activity")
            return
        }
        #expect(ordering.correctOrderIDs == ["open", "first", "second", "close", "score"])
        #expect(ordering.code(selectedFragmentIDs: ordering.correctOrderIDs)
                == "/*\nRevisit scoring\nTune the multiplier.\n*/\nlet score = 10")
        #expect(catalog.lessons.filter { $0.activity.kind == .codeOrdering }.count == 1)
        #expect(catalog.lessons.filter { $0.activity.kind == .diagnosticSelection }.count == 1)
        #expect(catalog.lessons.filter { $0.activity.kind == .codeRepair }.count == 1)
        #expect(catalog.lessons.filter { $0.activity.kind == .constrainedEditing }.count == 1)
        #expect(catalog.lessons.filter { $0.activity.kind == .missingCode }.count == 481)
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
    func codeOrderingFixtureUnlocksOnlyTheRepresentativeLesson() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            seedsCodeOrderingFixture: true
        )
        let viewModel = container.learningJourneyViewModel
        viewModel.load()
        let journey = try #require(viewModel.journey)
        let lesson = try #require(journey.catalog.lesson(id: "swift.comments.multiline"))
        let lessonIndex = try #require(journey.catalog.lessons.firstIndex { $0.id == lesson.id })

        #expect(journey.completedLessonCount == lessonIndex)
        #expect(journey.isUnlocked(lessonID: lesson.id))
        #expect(journey.isCompleted(lessonID: lesson.id) == false)
    }

    @Test
    func codeOrderingRejectsInvalidAndIncorrectResponsesBeforeCompleting() throws {
        let catalog = try bundledCatalog()
        let lesson = try #require(catalog.lesson(id: "swift.comments.multiline"))
        guard case let .codeOrdering(ordering) = lesson.activity else {
            Issue.record("Expected a code-ordering activity")
            return
        }
        let precedingIDs = Set(catalog.lessons.prefix { $0.id != lesson.id }.map(\.id))
        let progress = InMemoryLearningProgressRepository(completedLessonIDs: precedingIDs)
        let submit = SubmitLessonAnswerUseCase(
            contentRepository: InMemoryLearningContentRepository(catalog: catalog),
            progressRepository: progress
        )

        #expect(throws: LearningDomainError.invalidActivityResponse) {
            try submit.execute(lessonID: lesson.id, response: .orderedFragments(["open"]))
        }
        #expect(throws: LearningDomainError.invalidActivityResponse) {
            try submit.execute(
                lessonID: lesson.id,
                response: .orderedFragments(["open", "open", "second", "close", "score"])
            )
        }
        #expect(throws: LearningDomainError.invalidActivityResponse) {
            try submit.execute(
                lessonID: lesson.id,
                response: .orderedFragments(["open", "first", "unknown", "close", "score"])
            )
        }
        let incorrect = try submit.execute(
            lessonID: lesson.id,
            response: .orderedFragments(Array(ordering.correctOrderIDs.reversed()))
        )
        #expect(incorrect.isCorrect == false)
        #expect(progress.completedLessonIDs.contains(lesson.id) == false)

        let correct = try submit.execute(
            lessonID: lesson.id,
            response: .orderedFragments(ordering.correctOrderIDs)
        )
        #expect(correct.isCorrect)
        #expect(progress.completedLessonIDs.contains(lesson.id))
    }

    @Test
    func codeOrderingViewModelSupportsSelectionUndoAndCompletion() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            seedsCodeOrderingFixture: true
        )
        let viewModel = container.learningJourneyViewModel
        viewModel.load()
        let lesson = try #require(
            viewModel.journey?.catalog.lesson(id: "swift.comments.multiline")
        )
        guard case let .codeOrdering(ordering) = lesson.activity else {
            Issue.record("Expected a code-ordering activity")
            return
        }
        #expect(viewModel.canSubmit(lessonID: lesson.id) == false)
        for id in ordering.correctOrderIDs {
            viewModel.selectFragment(id, lessonID: lesson.id)
        }
        viewModel.selectFragment("open", lessonID: lesson.id)
        #expect(viewModel.selectedFragmentIDs == ordering.correctOrderIDs)
        viewModel.resetAttempt()
        #expect(viewModel.selectedFragmentIDs.isEmpty)
        #expect(viewModel.canSubmit(lessonID: lesson.id) == false)
        for id in ordering.correctOrderIDs {
            viewModel.selectFragment(id, lessonID: lesson.id)
        }
        viewModel.removeFragment("first")
        #expect(viewModel.canSubmit(lessonID: lesson.id) == false)
        viewModel.selectFragment("first", lessonID: lesson.id)
        #expect(viewModel.canSubmit(lessonID: lesson.id))
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == false)
        viewModel.resetAttempt()
        for id in ordering.correctOrderIDs {
            viewModel.selectFragment(id, lessonID: lesson.id)
        }
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.journey?.isCompleted(lessonID: lesson.id) == true)
    }

    @Test
    func codeOrderingReviewRecordsCorrectOutcome() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            resetsStoredData: true,
            seedsReviewFixture: true,
            seedsCodeOrderingFixture: true,
            clock: FixedLearningClock(now: Date(timeIntervalSince1970: 2_000_000_000)),
            // Fixed-clock attempts share a timestamp; sequential IDs keep ordering deterministic.
            idGenerator: SequentialLearningAttemptIDGenerator()
        )
        let viewModel = container.reviewQueueViewModel
        viewModel.load()
        let item = try #require(viewModel.currentItem)
        #expect(item.lesson.id == "swift.comments.multiline")
        guard case let .codeOrdering(ordering) = item.lesson.activity else {
            Issue.record("Expected a code-ordering review")
            return
        }
        for id in ordering.correctOrderIDs {
            viewModel.selectFragment(id)
        }
        #expect(viewModel.canSubmitCurrentItem)
        viewModel.submit(skillID: item.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.isSessionComplete)
    }

    @Test
    func diagnosticSelectionValidatesChoiceAndCompletesTheLesson() throws {
        let catalog = try bundledCatalog()
        let lesson = try #require(catalog.lesson(id: "swift.types.safety"))
        guard case let .diagnosticSelection(diagnostic) = lesson.activity else {
            Issue.record("Expected a diagnostic-selection activity")
            return
        }
        #expect(diagnostic.code == "let status: String = 42")
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            activityFixtureKind: .diagnosticSelection
        )
        let viewModel = container.learningJourneyViewModel
        viewModel.load()
        #expect(viewModel.journey?.isUnlocked(lessonID: lesson.id) == true)
        viewModel.selectChoice("build-success")
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == false)
        #expect(viewModel.journey?.isCompleted(lessonID: lesson.id) == false)
        viewModel.selectChoice(diagnostic.correctChoiceID)
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.journey?.isCompleted(lessonID: lesson.id) == true)
    }

    @Test
    func malformedDiagnosticSelectionPayloadIsRejected() throws {
        let resource = try #require(
            Bundle(for: AppContainer.self).url(
                forResource: "swift-6.4-beta-foundations",
                withExtension: "json"
            )
        )
        let original = try #require(
            String(data: Data(contentsOf: resource), encoding: .utf8)
        )
        let invalid = original.replacingOccurrences(
            of: "\"correctChoiceID\": \"type-error\"",
            with: "\"correctChoiceID\": \"unknown-diagnostic\""
        )
        #expect(invalid != original)
        let repository = BundledLearningContentRepository(data: Data(invalid.utf8))
        #expect(throws: LearningContentError.invalidActivityPayload("swift.types.safety")) {
            try repository.loadCatalog()
        }
    }

    @Test
    func diagnosticSelectionReviewRecordsTheChosenOutcome() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            resetsStoredData: true,
            seedsReviewFixture: true,
            activityFixtureKind: .diagnosticSelection,
            clock: FixedLearningClock(now: Date(timeIntervalSince1970: 2_000_000_000)),
            // Fixed-clock attempts share a timestamp; sequential IDs keep ordering deterministic.
            idGenerator: SequentialLearningAttemptIDGenerator()
        )
        let viewModel = container.reviewQueueViewModel
        viewModel.load()
        let item = try #require(viewModel.currentItem)
        #expect(item.lesson.id == "swift.types.safety")
        viewModel.selectChoice("type-error")
        viewModel.submit(skillID: item.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.isSessionComplete)
    }

    @Test
    func codeRepairShowsFaultAndValidatesTheReplacement() throws {
        let catalog = try bundledCatalog()
        let lesson = try #require(catalog.lesson(id: "swift.numbers.integer-conversion"))
        guard case let .codeRepair(repair) = lesson.activity else {
            Issue.record("Expected a code-repair activity")
            return
        }
        #expect(repair.code(selectedChoiceID: nil).hasSuffix("twoThousand + one"))
        #expect(repair.code(selectedChoiceID: repair.correctChoiceID)
                .hasSuffix("twoThousand + UInt16(one)"))
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            activityFixtureKind: .codeRepair
        )
        let viewModel = container.learningJourneyViewModel
        viewModel.load()
        #expect(viewModel.journey?.isUnlocked(lessonID: lesson.id) == true)
        viewModel.selectChoice("unconverted-uint8")
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == false)
        viewModel.selectChoice(repair.correctChoiceID)
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.journey?.isCompleted(lessonID: lesson.id) == true)
    }

    @Test
    func malformedCodeRepairPayloadIsRejected() throws {
        let resource = try #require(
            Bundle(for: AppContainer.self).url(
                forResource: "swift-6.4-beta-foundations",
                withExtension: "json"
            )
        )
        let original = try #require(
            String(data: Data(contentsOf: resource), encoding: .utf8)
        )
        let invalid = original.replacingOccurrences(
            of: "\"faultyCode\": \"one\"",
            with: "\"faultyCode\": \"\""
        )
        #expect(invalid != original)
        let repository = BundledLearningContentRepository(data: Data(invalid.utf8))
        #expect(throws: LearningContentError.invalidActivityPayload(
            "swift.numbers.integer-conversion"
        )) {
            try repository.loadCatalog()
        }
    }

    @Test
    func codeRepairReviewRecordsTheReplacementOutcome() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            resetsStoredData: true,
            seedsReviewFixture: true,
            activityFixtureKind: .codeRepair,
            clock: FixedLearningClock(now: Date(timeIntervalSince1970: 2_000_000_000)),
            // Fixed-clock attempts share a timestamp; sequential IDs keep ordering deterministic.
            idGenerator: SequentialLearningAttemptIDGenerator()
        )
        let viewModel = container.reviewQueueViewModel
        viewModel.load()
        let item = try #require(viewModel.currentItem)
        #expect(item.lesson.id == "swift.numbers.integer-conversion")
        viewModel.selectChoice("uint16-conversion")
        viewModel.submit(skillID: item.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.isSessionComplete)
    }

    @Test
    func constrainedEditingAcceptsOnlyBoundedAuthoredSolutions() throws {
        let catalog = try bundledCatalog()
        let lesson = try #require(catalog.lesson(id: "swift.numbers.integer-to-floating"))
        guard case let .constrainedEditing(editing) = lesson.activity else {
            Issue.record("Expected a constrained-editing activity")
            return
        }
        #expect(editing.code(enteredText: "Double(three)")
                .hasSuffix("Double(three) + fraction"))
        #expect(editing.text(selectedTokenIDs: editing.canonicalTokenIDs)
                == "Double(three)")
        let precedingIDs = Set(catalog.lessons.prefix { $0.id != lesson.id }.map(\.id))
        let progress = InMemoryLearningProgressRepository(completedLessonIDs: precedingIDs)
        let submit = SubmitLessonAnswerUseCase(
            contentRepository: InMemoryLearningContentRepository(catalog: catalog),
            progressRepository: progress
        )
        #expect(throws: LearningDomainError.invalidActivityResponse) {
            try submit.execute(lessonID: lesson.id, response: .text(""))
        }
        #expect(throws: LearningDomainError.invalidActivityResponse) {
            try submit.execute(lessonID: lesson.id, response: .text(String(repeating: "x", count: 31)))
        }
        #expect(throws: LearningDomainError.invalidActivityResponse) {
            try submit.execute(lessonID: lesson.id, response: .text("Double(\nthree)"))
        }
        let incorrect = try submit.execute(lessonID: lesson.id, response: .text("three"))
        #expect(incorrect.isCorrect == false)
        #expect(progress.completedLessonIDs.contains(lesson.id) == false)
        let correct = try submit.execute(
            lessonID: lesson.id,
            response: .text("Double(three)")
        )
        #expect(correct.isCorrect)
        #expect(progress.completedLessonIDs.contains(lesson.id))
    }

    @Test
    func constrainedEditingViewModelSupportsTextAndTokenDrafts() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            activityFixtureKind: .constrainedEditing
        )
        let viewModel = container.learningJourneyViewModel
        viewModel.load()
        let lesson = try #require(
            viewModel.journey?.catalog.lesson(id: "swift.numbers.integer-to-floating")
        )
        guard case let .constrainedEditing(editing) = lesson.activity else {
            Issue.record("Expected a constrained-editing activity")
            return
        }
        #expect(viewModel.canSubmit(lessonID: lesson.id) == false)
        for id in editing.canonicalTokenIDs {
            viewModel.selectToken(id, lessonID: lesson.id)
        }
        #expect(viewModel.selectedTokenIDs == editing.canonicalTokenIDs)
        #expect(viewModel.draftText == "Double(three)")
        viewModel.removeToken("value", lessonID: lesson.id)
        #expect(viewModel.draftText == "Double()")
        viewModel.editText("Double(three)")
        #expect(viewModel.selectedTokenIDs.isEmpty)
        viewModel.submit(lessonID: lesson.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.journey?.isCompleted(lessonID: lesson.id) == true)
    }

    @Test
    func malformedConstrainedEditingPayloadIsRejected() throws {
        let resource = try #require(
            Bundle(for: AppContainer.self).url(
                forResource: "swift-6.4-beta-foundations",
                withExtension: "json"
            )
        )
        let original = try #require(
            String(data: Data(contentsOf: resource), encoding: .utf8)
        )
        let invalid = original.replacingOccurrences(
            of: "\"canonicalTokenIDs\": [\"convert\", \"open\", \"value\", \"close\"]",
            with: "\"canonicalTokenIDs\": [\"value\", \"close\", \"convert\", \"open\"]"
        )
        #expect(invalid != original)
        let repository = BundledLearningContentRepository(data: Data(invalid.utf8))
        #expect(throws: LearningContentError.invalidActivityPayload(
            "swift.numbers.integer-to-floating"
        )) {
            try repository.loadCatalog()
        }
    }

    @Test
    func constrainedEditingReviewRecordsAuthoredSolution() throws {
        let container = try AppContainer(
            isStoredInMemoryOnly: true,
            resetsStoredData: true,
            seedsReviewFixture: true,
            activityFixtureKind: .constrainedEditing,
            clock: FixedLearningClock(now: Date(timeIntervalSince1970: 2_000_000_000)),
            // Fixed-clock attempts share a timestamp; sequential IDs keep ordering deterministic.
            idGenerator: SequentialLearningAttemptIDGenerator()
        )
        let viewModel = container.reviewQueueViewModel
        viewModel.load()
        let item = try #require(viewModel.currentItem)
        #expect(item.lesson.id == "swift.numbers.integer-to-floating")
        viewModel.editText("Double(three)")
        viewModel.submit(skillID: item.id)
        #expect(viewModel.attemptResult?.isCorrect == true)
        #expect(viewModel.isSessionComplete)
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
                response: correctResponse(for: lesson)
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
            switch correctResponse(for: lesson) {
            case let .choice(id):
                viewModel.selectChoice(id)
            case let .orderedFragments(ids):
                for id in ids {
                    viewModel.selectFragment(id, lessonID: lesson.id)
                }
            case let .text(text):
                viewModel.editText(text)
            case .classifications:
                Issue.record("Architecture labs must remain outside the Swift-book catalog")
            case .projectSubmission:
                Issue.record("Guided-project validation must remain outside book lessons")
            }
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
    func motivationRewardsOnlyValidatedUniqueLearningEvidence() throws {
        let catalog = try bundledCatalog()
        let lesson = try #require(catalog.lessons.first)
        let level = try #require(catalog.levels.first)
        let skillID = SkillID(rawValue: lesson.id)
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let correctEvidence = LearningEvidence(
            lessonID: lesson.id,
            skillID: skillID,
            activityID: lesson.activityID,
            outcome: .correct,
            errorCategory: nil
        )
        let reviewEvidence = LearningEvidence(
            lessonID: lesson.id,
            skillID: skillID,
            activityID: .review(skillID: skillID),
            outcome: .correct,
            errorCategory: nil
        )
        let attempts = InMemoryLearningAttemptRepository(attempts: [
            LearningAttempt(id: UUID(), evidence: correctEvidence, recordedAt: now),
            LearningAttempt(id: UUID(), evidence: correctEvidence, recordedAt: now),
            LearningAttempt(id: UUID(), evidence: reviewEvidence, recordedAt: now),
            LearningAttempt(
                id: UUID(),
                evidence: LearningEvidence(
                    lessonID: lesson.id,
                    skillID: skillID,
                    activityID: .review(skillID: skillID),
                    outcome: .incorrect,
                    errorCategory: .incorrectChoice
                ),
                recordedAt: now
            ),
            LearningAttempt(
                id: UUID(),
                evidence: LearningEvidence(
                    lessonID: lesson.id,
                    skillID: SkillID(rawValue: "invalid"),
                    activityID: lesson.activityID,
                    outcome: .correct,
                    errorCategory: nil
                ),
                recordedAt: now
            ),
            LearningAttempt(
                id: UUID(),
                evidence: LearningEvidence(
                    lessonID: lesson.id,
                    skillID: skillID,
                    activityID: .challenge(skillID: skillID),
                    outcome: .correct,
                    errorCategory: nil
                ),
                recordedAt: now
            )
        ])
        let boss = BossChallengeCompletion(
            challengeID: "boss.\(level.id)",
            levelID: level.id,
            completedAt: now
        )
        let bosses = InMemoryBossChallengeCompletionRepository(completions: [boss, boss])
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let projects = ContentLearningProjectRepository(contentRepository: content)
        let project = try #require(projects.loadProjects().first)
        let passedResults = try project.requirements.map { requirement in
            LearningProjectValidationResult(
                requirementID: requirement.id,
                lessonID: requirement.lesson.id,
                skillID: requirement.skillID,
                selectedChoiceID: try #require(requirement.lesson.correctChoiceID),
                outcome: .correct,
                feedback: requirement.lesson.correctFeedback
            )
        }
        var invalidPassedResults = passedResults
        let firstRequirement = try #require(passedResults.first)
        invalidPassedResults[0] = LearningProjectValidationResult(
            requirementID: firstRequirement.requirementID,
            lessonID: firstRequirement.lessonID,
            skillID: firstRequirement.skillID,
            selectedChoiceID: "invalid",
            outcome: .correct,
            feedback: firstRequirement.feedback
        )
        let submissions = InMemoryLearningProjectSubmissionRepository(submissions: [
            LearningProjectSubmission(
                id: UUID(), projectID: project.id,
                results: invalidPassedResults,
                submittedAt: now.addingTimeInterval(-1)
            ),
            LearningProjectSubmission(
                id: UUID(), projectID: project.id,
                results: passedResults, submittedAt: now
            ),
            LearningProjectSubmission(
                id: UUID(), projectID: project.id,
                results: passedResults, submittedAt: now
            )
        ])
        let progress = InMemoryLearningProgressRepository(completedLessonIDs: [lesson.id])
        let result = try makeMotivationUseCase(
            catalog: catalog, progress: progress, attempts: attempts,
            bosses: bosses, submissions: submissions, now: now
        ).execute()

        #expect(result.totalXP == 280)
        #expect(result.dailyXP == 280)
        #expect(result.weeklyXP == 280)
        #expect(result.streakDays == 1)
        #expect(result.recoveryTokens == 0)
        progress.completedLessonIDs.removeAll()
        #expect(try makeMotivationUseCase(
            catalog: catalog, progress: progress, attempts: attempts,
            bosses: bosses, submissions: submissions, now: now
        ).execute().totalXP == 260)
    }

    @Test
    func motivationUsesMondayWeekAndOneEarnedRecoveryToken() throws {
        let catalog = try bundledCatalog()
        let lesson = try #require(catalog.lessons.first)
        let skillID = SkillID(rawValue: lesson.id)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 7, hour: 12
        )))
        let review = LearningEvidence(
            lessonID: lesson.id,
            skillID: skillID,
            activityID: .review(skillID: skillID),
            outcome: .correct,
            errorCategory: nil
        )
        let dates = try (Array(0...6) + [8]).map { day -> Date in
            try #require(calendar.date(byAdding: .day, value: day, to: monday))
        }
        let attempts = InMemoryLearningAttemptRepository(attempts: dates.flatMap { date in
            (0..<2).map { _ in
                LearningAttempt(id: UUID(), evidence: review, recordedAt: date)
            }
        })
        let daySix = try #require(calendar.date(byAdding: .day, value: 6, to: monday))
        let earned = try makeMotivationUseCase(
            catalog: catalog, attempts: attempts, now: daySix, calendar: calendar
        ).execute()
        #expect(earned.streakDays == 7)
        #expect(earned.recoveryTokens == 1)

        let dayEight = try #require(calendar.date(byAdding: .day, value: 8, to: monday))
        let recovered = try makeMotivationUseCase(
            catalog: catalog, attempts: attempts, now: dayEight, calendar: calendar
        ).execute()
        #expect(recovered.totalXP == 160)
        #expect(recovered.dailyXP == 20)
        #expect(recovered.weeklyXP == 20)
        #expect(recovered.streakDays == 8)
        #expect(recovered.recoveryTokens == 0)

        let dayTen = try #require(calendar.date(byAdding: .day, value: 10, to: monday))
        let expired = try makeMotivationUseCase(
            catalog: catalog, attempts: attempts, now: dayTen, calendar: calendar
        ).execute()
        #expect(expired.streakDays == 0)
    }

    @Test
    func motivationFailureDoesNotInventRewards() throws {
        let catalog = try bundledCatalog()
        let viewModel = makeProfileViewModel(
            catalog: catalog,
            profileRepository: InMemoryLearnerProfileRepository(),
            motivationAttemptRepository: FailingLearningAttemptRepository()
        )
        viewModel.loadMotivationProgress()
        #expect(viewModel.motivationProgress == nil)
        #expect(viewModel.motivationState == .failed(
            FixtureError.attemptsUnavailable.localizedDescription
        ))

        let content = InMemoryLearningContentRepository(catalog: catalog)
        let projects = ContentLearningProjectRepository(contentRepository: content)
        let useCase = LoadMotivationProgressUseCase(
            contentRepository: content,
            progressRepository: InMemoryLearningProgressRepository(),
            loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                contentRepository: content,
                skillRepository: ContentCanonicalSkillRepository(
                    contentRepository: content,
                    projectRepository: projects
                )
            ),
            attemptRepository: FailingLearningAttemptRepository(),
            bossCompletionRepository: InMemoryBossChallengeCompletionRepository(),
            projectRepository: projects,
            projectSubmissionRepository: InMemoryLearningProjectSubmissionRepository(),
            clock: FixedLearningClock(now: Date(timeIntervalSince1970: 1_000))
        )
        #expect(throws: FixtureError.attemptsUnavailable) {
            try useCase.execute()
        }
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

        viewModel.load()
        #expect(viewModel.snapshot?.profile.avatar == .girl)
        #expect(viewModel.draftAvatar == .girl)

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
            choiceID: try #require(first.lesson.correctChoiceID)
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
        viewModel.selectChoice(try #require(first.lesson.correctChoiceID))
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
        viewModel.selectChoice(try #require(second.lesson.correctChoiceID))
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
            viewModel.selectChoice(try #require(item.lesson.correctChoiceID))
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
        let passedResults = try project.requirements.map { requirement in
            LearningProjectValidationResult(
                requirementID: requirement.id,
                lessonID: requirement.lesson.id,
                skillID: requirement.skillID,
                selectedChoiceID: try #require(requirement.lesson.correctChoiceID),
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
        let responses = try project.requirements.map { requirement in
            LearningProjectResponse(
                requirementID: requirement.id,
                choiceID: requirement.id == incorrectRequirement.id
                    ? incorrectChoice.id
                    : try #require(requirement.lesson.correctChoiceID)
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
        let validation = ProjectValidationActivity(project: project, submission: submission)
        let validationActivity = LearningActivity.projectValidation(validation)
        #expect(validation.schemaVersion == 1)
        #expect(validationActivity.accepts(.projectSubmission(submission)))
        #expect(!validationActivity.isCorrect(.projectSubmission(submission)))
        #expect(validation.checklist.count == project.requirements.count)
        #expect(validation.checklist.first {
            $0.id == incorrectRequirement.id
        }?.status == .needsReview)
        let foreignSubmission = LearningProjectSubmission(
            id: submission.id,
            projectID: "another.project",
            results: submission.results,
            submittedAt: submission.submittedAt
        )
        #expect(!validationActivity.accepts(.projectSubmission(foreignSubmission)))
        let duplicatedSubmission = LearningProjectSubmission(
            id: submission.id,
            projectID: project.id,
            results: [submission.results[0], submission.results[0], submission.results[2]],
            submittedAt: submission.submittedAt
        )
        #expect(!validationActivity.accepts(.projectSubmission(duplicatedSubmission)))
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
        guard case let .projectValidation(initialValidation) = viewModel.projectValidationActivity else {
            Issue.record("Expected project validation activity before submission")
            return
        }
        #expect(initialValidation.schemaVersion == 1)
        #expect(initialValidation.checklist.allSatisfy { $0.status == .pending })

        for (index, requirement) in project.requirements.enumerated() {
            #expect(viewModel.currentRequirement?.id == requirement.id)
            #expect(viewModel.selectedChoiceID == nil)
            #expect(viewModel.responses.count == index)
            viewModel.continueProject()
            #expect(viewModel.currentRequirement?.id == requirement.id)
            #expect(viewModel.responses.count == index)
            viewModel.selectChoice(try #require(requirement.lesson.correctChoiceID))
            viewModel.continueProject()
            if index < project.requirements.count - 1 {
                #expect(viewModel.currentRequirementIndex == index + 1)
                #expect(viewModel.attemptRevision == 0)
            }
        }

        #expect(viewModel.submission?.isPassed == true)
        guard case let .projectValidation(finalValidation) = viewModel.projectValidationActivity,
              let finalSubmission = viewModel.submission else {
            Issue.record("Expected project validation activity after submission")
            return
        }
        #expect(finalValidation.checklist.allSatisfy { $0.status == .passed })
        #expect(finalValidation.accepts(finalSubmission))
        #expect(LearningActivity.projectValidation(finalValidation)
            .isCorrect(.projectSubmission(finalSubmission)))
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

    private func correctResponse(for lesson: LearningLesson) -> LearningActivityResponse {
        switch lesson.activity {
        case let .missingCode(activity):
            .choice(activity.correctChoiceID)
        case let .outputPrediction(activity):
            .choice(activity.correctChoiceID)
        case let .codeOrdering(activity):
            .orderedFragments(activity.correctOrderIDs)
        case let .diagnosticSelection(activity):
            .choice(activity.correctChoiceID)
        case let .codeRepair(activity):
            .choice(activity.correctChoiceID)
        case let .constrainedEditing(activity):
            .text(activity.acceptedSolutions[0])
        case let .unitTestAuthoring(activity):
            .text(activity.composition.acceptedSolutions[0])
        case let .uiTestAuthoring(activity):
            .text(activity.composition.acceptedSolutions[0])
        case let .architectureClassification(activity):
            .classifications(Dictionary(uniqueKeysWithValues: activity.items.map {
                ($0.id, $0.correctLayer)
            }))
        case .projectValidation:
            preconditionFailure("Guided-project validation is not a Swift-book lesson")
        }
    }

    private func makeMotivationUseCase(
        catalog: LearningCatalog,
        progress: InMemoryLearningProgressRepository = .init(),
        attempts: InMemoryLearningAttemptRepository = .init(),
        bosses: InMemoryBossChallengeCompletionRepository = .init(),
        submissions: InMemoryLearningProjectSubmissionRepository = .init(),
        now: Date,
        calendar: Calendar = .current
    ) -> LoadMotivationProgressUseCase {
        let content = InMemoryLearningContentRepository(catalog: catalog)
        let projects = ContentLearningProjectRepository(contentRepository: content)
        return LoadMotivationProgressUseCase(
            contentRepository: content,
            progressRepository: progress,
            loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                contentRepository: content,
                skillRepository: ContentCanonicalSkillRepository(
                    contentRepository: content,
                    projectRepository: projects
                )
            ),
            attemptRepository: attempts,
            bossCompletionRepository: bosses,
            projectRepository: projects,
            projectSubmissionRepository: submissions,
            clock: FixedLearningClock(now: now),
            calendar: calendar
        )
    }

    private func makeProfileViewModel(
        catalog: LearningCatalog,
        profileRepository: any LearnerProfileRepository,
        progressRepository: InMemoryLearningProgressRepository = .init(),
        attemptRepository: InMemoryLearningAttemptRepository = .init(),
        recentAttemptRepository: (any LearningAttemptRepository)? = nil,
        motivationAttemptRepository: (any LearningAttemptRepository)? = nil,
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
            loadMotivationProgress: LoadMotivationProgressUseCase(
                contentRepository: contentRepository,
                progressRepository: progressRepository,
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: motivationAttemptRepository ?? attemptRepository,
                bossCompletionRepository: bossCompletionRepository,
                projectRepository: projectRepository,
                projectSubmissionRepository: projectSubmissionRepository,
                clock: FixedLearningClock(now: Date(timeIntervalSince1970: 1_000))
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

/// Produces ascending UUIDs so same-timestamp attempts sort in recording order.
private final class SequentialLearningAttemptIDGenerator: LearningAttemptIDGenerating {
    private var byte: UInt8 = 1

    func next() -> UUID {
        defer { byte &+= 1 }
        return UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, byte))
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
