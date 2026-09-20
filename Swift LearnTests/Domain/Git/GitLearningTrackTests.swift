import Foundation
import SwiftData
import Testing
@testable import Swift_Learn

@MainActor
struct GitLearningTrackTests {
    @Test
    func bundledCatalogValidatesAndKeepsUniqueCommands() throws {
        let catalog = try bundledCatalog()

        try ValidateGitCommandCatalogUseCase().execute(catalog)

        #expect(catalog.lessons.isEmpty == false)
        #expect(Set(catalog.lessons.map(\.id)).count == catalog.lessonCount)
        #expect(
            Set(catalog.lessons.map(\.canonicalCommand)).count == catalog.lessonCount
        )
        for lesson in catalog.lessons {
            #expect(lesson.scenario.isEmpty == false)
            #expect(lesson.prompt.isEmpty == false)
            #expect(lesson.choices.count >= 2)
            #expect(lesson.correctFeedback.isEmpty == false)
            #expect(lesson.incorrectFeedback.isEmpty == false)
            #expect(lesson.sourceReferences.isEmpty == false)
            #expect(lesson.categoryID.isEmpty == false)
            if lesson.safetyLevel.requiresWarning {
                #expect(lesson.safetyWarning?.isEmpty == false)
            }
        }
    }

    @Test
    func validationRejectsDuplicateIDsUnknownAnswersAndMissingWarnings() {
        let duplicate = makeCatalog(
            lessons: [makeLesson(id: "a"), makeLesson(id: "a", command: "git fsck")]
        )
        #expect(throws: GitCatalogError.duplicateLessonID("a")) {
            try ValidateGitCommandCatalogUseCase().execute(duplicate)
        }

        let unknownAnswer = makeCatalog(
            lessons: [makeLesson(id: "b", correctChoiceID: "missing")]
        )
        #expect(throws: GitCatalogError.unknownCorrectChoice("b")) {
            try ValidateGitCommandCatalogUseCase().execute(unknownAnswer)
        }

        let unwarned = makeCatalog(
            lessons: [
                makeLesson(id: "c", safetyLevel: .historyMutation, safetyWarning: nil)
            ]
        )
        #expect(throws: GitCatalogError.missingSafetyWarning("c")) {
            try ValidateGitCommandCatalogUseCase().execute(unwarned)
        }
    }

    @Test
    func onlyTheFirstQuestionUnlocksBeforeAnyProgress() throws {
        let track = GitLearningTrack(
            catalog: try bundledCatalog(),
            completedLessonIDs: []
        )
        let lessons = track.catalog.lessons

        #expect(track.isUnlocked(lessonID: lessons[0].id))
        #expect(track.isUnlocked(lessonID: lessons[1].id) == false)
        #expect(track.completedLessonCount == 0)
        #expect(track.progress == 0)
        #expect(track.currentLesson?.id == lessons[0].id)
        #expect(track.isTrackComplete == false)
    }

    @Test
    func correctAnswerCompletesAndUnlocksTheNextQuestion() throws {
        let catalog = try bundledCatalog()
        let first = catalog.lessons[0]
        let progress = InMemoryGitTrackRepository()
        let useCase = SubmitGitAnswerUseCase(
            contentRepository: BundledGitCommandRepository(data: try bundledData()),
            progressRepository: progress,
            attemptRepository: progress,
            clock: GitTestClock()
        )

        let result = try useCase.execute(
            lessonID: first.id,
            choiceID: first.correctChoiceID
        )

        #expect(result.isCorrect)
        #expect(result.didComplete)
        #expect(result.feedback == first.correctFeedback)
        let track = GitLearningTrack(
            catalog: catalog,
            completedLessonIDs: try progress.loadCompletedLessonIDs()
        )
        #expect(track.isCompleted(lessonID: first.id))
        #expect(track.isUnlocked(lessonID: catalog.lessons[1].id))
        #expect(try progress.attemptCount() == 1)
    }

    @Test
    func incorrectAnswerRecordsAnAttemptWithoutCompleting() throws {
        let catalog = try bundledCatalog()
        let first = catalog.lessons[0]
        let wrong = try #require(
            first.choices.first { $0.id != first.correctChoiceID }
        )
        let progress = InMemoryGitTrackRepository()
        let useCase = SubmitGitAnswerUseCase(
            contentRepository: BundledGitCommandRepository(data: try bundledData()),
            progressRepository: progress,
            attemptRepository: progress,
            clock: GitTestClock()
        )

        let result = try useCase.execute(lessonID: first.id, choiceID: wrong.id)

        #expect(result.isCorrect == false)
        #expect(result.didComplete == false)
        #expect(result.feedback == first.incorrectFeedback)
        #expect(try progress.loadCompletedLessonIDs().isEmpty)
        #expect(try progress.attemptCount() == 1)
    }

    @Test
    func lockedQuestionsAndUnknownAnswersAreRejected() throws {
        let catalog = try bundledCatalog()
        let progress = InMemoryGitTrackRepository()
        let useCase = SubmitGitAnswerUseCase(
            contentRepository: BundledGitCommandRepository(data: try bundledData()),
            progressRepository: progress,
            attemptRepository: progress,
            clock: GitTestClock()
        )
        let locked = catalog.lessons[1]

        #expect(throws: GitLearningDomainError.lessonLocked(locked.id)) {
            try useCase.execute(lessonID: locked.id, choiceID: locked.correctChoiceID)
        }
        #expect(throws: GitLearningDomainError.lessonNotFound("git.unknown")) {
            try useCase.execute(lessonID: "git.unknown", choiceID: "x")
        }
        #expect(
            throws: GitLearningDomainError.choiceNotFound("not-a-choice")
        ) {
            try useCase.execute(
                lessonID: catalog.lessons[0].id,
                choiceID: "not-a-choice"
            )
        }
        #expect(try progress.attemptCount() == 0)
    }

    @Test
    func gitProgressAndResetNeverTouchSwiftRecords() throws {
        let container = try ModelContainer(
            for: Schema(versionedSchema: SwiftLearnSchemaV8.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(
            LessonProgressRecord(lessonID: "swift.bindings.constants", completedAt: .now)
        )
        context.insert(
            LearningAttemptRecord(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
                lessonID: "swift.bindings.constants",
                skillID: "swift.bindings.constants",
                activityID: "swift.bindings.constants",
                outcomeRawValue: "correct",
                errorCategoryRawValue: nil,
                recordedAt: .now
            )
        )
        try context.save()

        let repository = SwiftDataGitTrackRepository(modelContext: context)
        try repository.markCompleted(lessonID: "git.maintenance.gc")
        try repository.recordAttempt(
            lessonID: "git.maintenance.gc",
            choiceID: "git-gc",
            isCorrect: true,
            recordedAt: .now
        )

        #expect(try repository.loadCompletedLessonIDs() == ["git.maintenance.gc"])
        #expect(try repository.attemptCount() == 1)

        try ResetGitTrackProgressUseCase(repository: repository).execute()

        #expect(try repository.loadCompletedLessonIDs().isEmpty)
        #expect(try repository.attemptCount() == 0)
        let swiftProgress = try context.fetch(FetchDescriptor<LessonProgressRecord>())
        let swiftAttempts = try context.fetch(FetchDescriptor<LearningAttemptRecord>())
        #expect(swiftProgress.count == 1)
        #expect(swiftProgress.first?.learningTrackID == .swift)
        #expect(swiftAttempts.count == 1)
        #expect(swiftAttempts.first?.learningTrackID == .swift)
    }

    @Test
    func swiftResetLeavesGitProgressUntouched() throws {
        let container = try ModelContainer(
            for: Schema(versionedSchema: SwiftLearnSchemaV8.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let git = SwiftDataGitTrackRepository(modelContext: context)
        try git.markCompleted(lessonID: "git.maintenance.gc")
        context.insert(
            LessonProgressRecord(lessonID: "swift.bindings.constants", completedAt: .now)
        )
        try context.save()

        try SwiftDataLearningResetRepository(
            modelContext: context,
            syncGeneration: GitTestSyncGeneration()
        ).resetLearningProgress()

        #expect(try context.fetch(FetchDescriptor<LessonProgressRecord>()).isEmpty)
        #expect(try git.loadCompletedLessonIDs() == ["git.maintenance.gc"])
    }

    // MARK: - Fixtures

    private func bundledData() throws -> Data {
        let bundle = Bundle(for: GitTestBundleToken.self)
        let url = try #require(
            bundle.url(forResource: "git-commands-foundations", withExtension: "json")
                ?? Bundle.main.url(
                    forResource: "git-commands-foundations",
                    withExtension: "json"
                )
        )
        return try Data(contentsOf: url)
    }

    private func bundledCatalog() throws -> GitCommandCatalog {
        try BundledGitCommandRepository(data: try bundledData()).loadCatalog()
    }

    private func makeCatalog(lessons: [GitCommandLesson]) -> GitCommandCatalog {
        GitCommandCatalog(
            sourceID: "test",
            editionTitle: "Test",
            categories: [
                GitCommandCategory(
                    id: "test",
                    title: "Test",
                    summary: "Test",
                    lessons: lessons
                )
            ]
        )
    }

    private func makeLesson(
        id: String,
        command: String = "git status",
        correctChoiceID: String = "a",
        safetyLevel: GitCommandSafetyLevel = .readOnly,
        safetyWarning: String? = nil
    ) -> GitCommandLesson {
        GitCommandLesson(
            id: id,
            title: "Title",
            objective: "Objective",
            scenario: "Scenario",
            prompt: "Prompt",
            choices: [
                GitCommandChoice(id: "a", command: command),
                GitCommandChoice(id: "b", command: "git log")
            ],
            correctChoiceID: correctChoiceID,
            correctFeedback: "Correct",
            incorrectFeedback: "Incorrect",
            categoryID: "test",
            sourceReferences: ["plan:test"],
            safetyLevel: safetyLevel,
            safetyWarning: safetyWarning
        )
    }
}

private final class GitTestBundleToken {}

@MainActor
private struct GitTestClock: LearningClock {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
}

@MainActor
private struct GitTestSyncGeneration: LearningSyncResetGenerationAdvancing {
    func advanceResetGeneration() throws {}
}
