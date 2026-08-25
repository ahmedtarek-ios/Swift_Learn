//
//  LearningEvidenceTests.swift
//  Swift LearnTests
//
//  Created by Codex on 25/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Swift_Learn

@MainActor
struct LearningEvidenceTests {
    @Test
    func bundledCatalogMapsEveryLessonToOneUniqueCanonicalSkill() throws {
        let content = BundledLearningContentRepository(
            bundle: Bundle(for: AppContainer.self)
        )
        let skills = try LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: ContentCanonicalSkillRepository(
                contentRepository: content
            )
        ).execute()
        let catalog = try content.loadCatalog()

        #expect(skills.count == catalog.lessons.count)
        #expect(Set(skills.map(\.id)).count == skills.count)
        #expect(skills.flatMap(\.lessonIDs).count == catalog.lessons.count)
    }

    @Test
    func repeatedLessonsReuseOneCanonicalSkillIdentity() throws {
        let catalog = makeCatalog(lessonIDs: ["lesson.one", "lesson.two"])
        let sharedSkill = CanonicalSkill(
            id: SkillID(rawValue: "skill.shared"),
            title: "Shared Skill",
            lessonIDs: ["lesson.one", "lesson.two"],
            activityIDs: [
                LearningActivityID(rawValue: "lesson.one"),
                LearningActivityID(rawValue: "lesson.two")
            ]
        )
        let skills = try LoadCanonicalSkillsUseCase(
            contentRepository: E1ContentRepository(catalog: catalog),
            skillRepository: E1SkillRepository(skills: [sharedSkill])
        ).execute()

        #expect(skills == [sharedSkill])
    }

    @Test
    func canonicalSkillValidationRejectsMissingAndDuplicateLessonMappings() {
        let catalog = makeCatalog(lessonIDs: ["lesson.one", "lesson.two"])
        let duplicateSkills = [
            makeSkill(id: "skill.one", lessonID: "lesson.one"),
            makeSkill(id: "skill.two", lessonID: "lesson.one")
        ]
        let duplicateUseCase = LoadCanonicalSkillsUseCase(
            contentRepository: E1ContentRepository(catalog: catalog),
            skillRepository: E1SkillRepository(skills: duplicateSkills)
        )

        #expect(
            throws: LearningEvidenceDomainError.duplicateLessonMapping("lesson.one")
        ) {
            try duplicateUseCase.execute()
        }

        let missingUseCase = LoadCanonicalSkillsUseCase(
            contentRepository: E1ContentRepository(catalog: catalog),
            skillRepository: E1SkillRepository(
                skills: [makeSkill(id: "skill.one", lessonID: "lesson.one")]
            )
        )
        #expect(
            throws: LearningEvidenceDomainError.missingLessonMapping("lesson.two")
        ) {
            try missingUseCase.execute()
        }

        let duplicateActivityUseCase = LoadCanonicalSkillsUseCase(
            contentRepository: E1ContentRepository(catalog: catalog),
            skillRepository: E1SkillRepository(
                skills: [
                    CanonicalSkill(
                        id: SkillID(rawValue: "skill.one"),
                        title: "One",
                        lessonIDs: ["lesson.one"],
                        activityIDs: [LearningActivityID(rawValue: "lesson.one")]
                    ),
                    CanonicalSkill(
                        id: SkillID(rawValue: "skill.two"),
                        title: "Two",
                        lessonIDs: ["lesson.two"],
                        activityIDs: [LearningActivityID(rawValue: "lesson.one")]
                    )
                ]
            )
        )
        #expect(
            throws: LearningEvidenceDomainError.duplicateActivityMapping("lesson.one")
        ) {
            try duplicateActivityUseCase.execute()
        }
    }

    @Test
    func correctAndIncorrectAttemptsUseInjectedClockAndCategoryPolicy() throws {
        let date = Date(timeIntervalSince1970: 4_242)
        let repository = E1AttemptRepository()
        let useCase = makeRecordUseCase(
            attemptRepository: repository,
            date: date
        )

        let correct = try useCase.execute(
            lessonID: "lesson.one",
            activityID: LearningActivityID(rawValue: "lesson.one"),
            outcome: .correct,
            errorCategory: .logic
        )
        let incorrect = try useCase.execute(
            lessonID: "lesson.one",
            activityID: LearningActivityID(rawValue: "lesson.one"),
            outcome: .incorrect
        )

        #expect(repository.attempts.count == 2)
        #expect(correct.recordedAt == date)
        #expect(correct.evidence.errorCategory == nil)
        #expect(incorrect.recordedAt == date)
        #expect(incorrect.evidence.errorCategory == .incorrectChoice)
    }

    @Test
    func recordAttemptRejectsUnknownLessonAndActivityIdentifiers() {
        let useCase = makeRecordUseCase()

        #expect(
            throws: LearningEvidenceDomainError.unknownLessonID("missing.lesson")
        ) {
            try useCase.execute(
                lessonID: "missing.lesson",
                activityID: LearningActivityID(rawValue: "missing.lesson"),
                outcome: .incorrect
            )
        }
        #expect(
            throws: LearningEvidenceDomainError.unknownActivityID("missing.activity")
        ) {
            try useCase.execute(
                lessonID: "lesson.one",
                activityID: LearningActivityID(rawValue: "missing.activity"),
                outcome: .incorrect
            )
        }
    }

    @Test
    func attemptHistoryRejectsUnknownSkillAndSortsDeterministically() throws {
        let repository = E1AttemptRepository(
            attempts: [
                makeAttempt(idByte: 2, recordedAt: Date(timeIntervalSince1970: 20)),
                makeAttempt(idByte: 1, recordedAt: Date(timeIntervalSince1970: 10))
            ]
        )
        let loadSkills = makeLoadSkillsUseCase()
        let useCase = LoadSkillAttemptHistoryUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: repository
        )

        let history = try useCase.execute(skillID: SkillID(rawValue: "lesson.one"))
        #expect(history.map(\.recordedAt) == [
            Date(timeIntervalSince1970: 10),
            Date(timeIntervalSince1970: 20)
        ])
        #expect(
            throws: LearningEvidenceDomainError.unknownSkillID("missing.skill")
        ) {
            try useCase.execute(skillID: SkillID(rawValue: "missing.skill"))
        }
    }

    @Test
    func swiftDataAttemptRepositoryRoundTripsEvidence() throws {
        let container = try AppContainer(isStoredInMemoryOnly: true)
        let repository = SwiftDataLearningAttemptRepository(
            modelContext: container.modelContainer.mainContext
        )
        let attempt = makeAttempt(
            idByte: 7,
            recordedAt: Date(timeIntervalSince1970: 77),
            outcome: .incorrect,
            errorCategory: .syntax
        )

        try repository.record(attempt)

        #expect(
            try repository.loadAttempts(skillID: SkillID(rawValue: "lesson.one"))
                == [attempt]
        )
        #expect(
            try repository.loadAttempts(skillID: SkillID(rawValue: "other.skill"))
                .isEmpty
        )
    }

    @Test
    func schemaMigrationPreservesExistingProgressAndProfileRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "SwiftLearnMigration-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "SwiftLearn.store")

        try createV1Store(at: storeURL)

        let upgraded = try AppContainer(
            storageName: "MigrationVerification",
            storageURL: storeURL
        )
        let context = upgraded.modelContainer.mainContext
        #expect(
            try context.fetch(FetchDescriptor<LessonProgressRecord>())
                .map(\.lessonID) == ["lesson.one"]
        )
        #expect(
            try context.fetch(FetchDescriptor<LearnerProfileRecord>())
                .map(\.displayName) == ["Migration Learner"]
        )
        #expect(try context.fetch(FetchDescriptor<LearningAttemptRecord>()).isEmpty)
    }

    @Test
    func viewModelRecordsCorrectAndIncorrectSubmissionsOnce() {
        let attempts = E1AttemptRepository()
        let viewModel = makeViewModel(attemptRepository: attempts)
        viewModel.load()

        viewModel.selectChoice("incorrect")
        viewModel.submit(lessonID: "lesson.one")
        #expect(attempts.attempts.map(\.evidence.outcome) == [.incorrect])
        #expect(viewModel.attemptRevision == 1)

        viewModel.resetAttempt()
        viewModel.selectChoice("correct")
        viewModel.submit(lessonID: "lesson.one")

        #expect(attempts.attempts.map(\.evidence.outcome) == [.incorrect, .correct])
        #expect(viewModel.attemptRevision == 2)
        #expect(viewModel.journey?.completedLessonIDs == ["lesson.one"])
    }

    @Test
    func attemptRepositoryFailurePropagatesToViewModel() {
        let repository = E1AttemptRepository(recordError: E1FixtureError.attemptUnavailable)
        let viewModel = makeViewModel(attemptRepository: repository)
        viewModel.load()
        viewModel.selectChoice("incorrect")

        viewModel.submit(lessonID: "lesson.one")

        #expect(viewModel.attemptResult?.isCorrect == false)
        #expect(viewModel.attemptResult?.feedback == "Attempt history unavailable")
        #expect(repository.attempts.isEmpty)
    }

    private func makeViewModel(
        attemptRepository: E1AttemptRepository
    ) -> LearningJourneyViewModel {
        let content = E1ContentRepository(catalog: makeCatalog())
        let progress = E1ProgressRepository()
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
                loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                    contentRepository: content,
                    skillRepository: E1SkillRepository(
                        skills: [makeSkill()]
                    )
                ),
                attemptRepository: attemptRepository,
                clock: E1Clock(now: Date(timeIntervalSince1970: 100)),
                idGenerator: E1IDGenerator()
            ),
            calculateProgressEvents: CalculateLearningProgressEventsUseCase(
                calculateAchievements: CalculateAchievementsUseCase()
            )
        )
    }

    private func makeRecordUseCase(
        attemptRepository: E1AttemptRepository = E1AttemptRepository(),
        date: Date = Date(timeIntervalSince1970: 100)
    ) -> RecordLearningAttemptUseCase {
        RecordLearningAttemptUseCase(
            loadCanonicalSkills: makeLoadSkillsUseCase(),
            attemptRepository: attemptRepository,
            clock: E1Clock(now: date),
            idGenerator: E1IDGenerator()
        )
    }

    private func makeLoadSkillsUseCase() -> LoadCanonicalSkillsUseCase {
        LoadCanonicalSkillsUseCase(
            contentRepository: E1ContentRepository(catalog: makeCatalog()),
            skillRepository: E1SkillRepository(skills: [makeSkill()])
        )
    }

    private func makeCatalog(
        lessonIDs: [String] = ["lesson.one"]
    ) -> LearningCatalog {
        LearningCatalog(
            sourceID: "fixture",
            editionTitle: "Fixture",
            levels: [
                LearningLevel(
                    id: "level.one",
                    title: "Level",
                    summary: "Summary",
                    lessons: lessonIDs.map(makeLesson(id:))
                )
            ]
        )
    }

    private func makeLesson(id: String) -> LearningLesson {
        LearningLesson(
            id: id,
            title: id,
            objective: "Practice",
            instruction: "Choose",
            codePrefix: "",
            codeSuffix: "",
            choices: [
                LearningChoice(id: "correct", code: "let"),
                LearningChoice(id: "incorrect", code: "var")
            ],
            correctChoiceID: "correct",
            correctFeedback: "Correct",
            incorrectFeedback: "Incorrect",
            sourceTitle: "Fixture",
            sourceReferences: ["fixture"]
        )
    }

    private func makeSkill(
        id: String = "lesson.one",
        lessonID: String = "lesson.one"
    ) -> CanonicalSkill {
        CanonicalSkill(
            id: SkillID(rawValue: id),
            title: id,
            lessonIDs: [lessonID],
            activityIDs: [LearningActivityID(rawValue: lessonID)]
        )
    }

    private func makeAttempt(
        idByte: UInt8,
        recordedAt: Date,
        outcome: AttemptOutcome = .correct,
        errorCategory: LearningErrorCategory? = nil
    ) -> LearningAttempt {
        LearningAttempt(
            id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, idByte)),
            evidence: LearningEvidence(
                lessonID: "lesson.one",
                skillID: SkillID(rawValue: "lesson.one"),
                activityID: LearningActivityID(rawValue: "lesson.one"),
                outcome: outcome,
                errorCategory: errorCategory
            ),
            recordedAt: recordedAt
        )
    }

    private func createV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SwiftLearnSchemaV1.self)
        let configuration = ModelConfiguration(
            "MigrationVerification",
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        container.mainContext.insert(
            LessonProgressRecord(
                lessonID: "lesson.one",
                completedAt: Date(timeIntervalSince1970: 1)
            )
        )
        container.mainContext.insert(
            LearnerProfileRecord(
                displayName: "Migration Learner",
                avatarRawValue: LearnerAvatar.terminal.rawValue,
                appearanceRawValue: LearnerAppearance.dark.rawValue
            )
        )
        try container.mainContext.save()
    }
}

@MainActor
private final class E1ContentRepository: LearningContentRepository {
    let catalog: LearningCatalog

    init(catalog: LearningCatalog) {
        self.catalog = catalog
    }

    func loadCatalog() -> LearningCatalog {
        catalog
    }
}

@MainActor
private final class E1SkillRepository: CanonicalSkillRepository {
    let skills: [CanonicalSkill]

    init(skills: [CanonicalSkill]) {
        self.skills = skills
    }

    func loadCanonicalSkills() -> [CanonicalSkill] {
        skills
    }
}

@MainActor
private final class E1AttemptRepository: LearningAttemptRepository {
    private(set) var attempts: [LearningAttempt]
    private let recordError: (any Error)?

    init(
        attempts: [LearningAttempt] = [],
        recordError: (any Error)? = nil
    ) {
        self.attempts = attempts
        self.recordError = recordError
    }

    func record(_ attempt: LearningAttempt) throws {
        if let recordError {
            throw recordError
        }
        attempts.append(attempt)
    }

    func loadAttempts(skillID: SkillID) -> [LearningAttempt] {
        attempts.filter { $0.evidence.skillID == skillID }
    }

    func loadAllAttempts() -> [LearningAttempt] {
        attempts
    }
}

@MainActor
private final class E1ProgressRepository: LearningProgressRepository {
    private(set) var completedLessonIDs = Set<String>()

    func loadCompletedLessonIDs() -> Set<String> {
        completedLessonIDs
    }

    func markCompleted(lessonID: String) {
        completedLessonIDs.insert(lessonID)
    }
}

@MainActor
private struct E1Clock: LearningClock {
    let now: Date
}

@MainActor
private final class E1IDGenerator: LearningAttemptIDGenerating {
    private var nextByte: UInt8 = 1

    func next() -> UUID {
        defer { nextByte &+= 1 }
        return UUID(
            uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, nextByte)
        )
    }
}

private enum E1FixtureError: LocalizedError {
    case attemptUnavailable

    var errorDescription: String? {
        "Attempt history unavailable"
    }
}
