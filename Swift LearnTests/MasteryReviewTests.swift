//
//  MasteryReviewTests.swift
//  Swift LearnTests
//
//  Created by Codex on 25/08/2026.
//

import Foundation
import Testing
@testable import Swift_Learn

@MainActor
struct MasteryReviewTests {
    private let day: TimeInterval = 86_400

    @Test
    func completionAloneAndIncorrectEvidenceNeverProduceMastery() {
        let useCase = CalculateSkillMasteryUseCase()
        let skillID = SkillID(rawValue: "skill.one")
        let now = Date(timeIntervalSince1970: 100)

        let completionOnly = useCase.execute(
            skillID: skillID,
            attempts: [],
            now: now
        )
        let incorrect = useCase.execute(
            skillID: skillID,
            attempts: [makeAttempt(skillID: skillID, outcome: .incorrect, at: now)],
            now: now
        )

        #expect(completionOnly.level == .unseen)
        #expect(completionOnly.correctAttemptCount == 0)
        #expect(incorrect.level == .reviewDue)
        #expect(incorrect.correctAttemptCount == 0)
    }

    @Test
    func schedulingPolicyUsesOutcomeCountAndActivityDifficulty() throws {
        let schedule = ScheduleSkillReviewUseCase()
        let start = Date(timeIntervalSince1970: 1_000)
        let skillID = SkillID(rawValue: "skill.one")
        let cases: [(LearningAttempt, TimeInterval)] = [
            (makeAttempt(skillID: skillID, outcome: .incorrect, at: start), 0),
            (makeAttempt(skillID: skillID, outcome: .correct, at: start), day),
            (
                makeAttempt(
                    skillID: skillID,
                    activityID: .review(skillID: skillID),
                    outcome: .correct,
                    at: start
                ),
                3 * day
            ),
            (
                makeAttempt(
                    skillID: skillID,
                    activityID: .challenge(skillID: skillID),
                    outcome: .correct,
                    at: start
                ),
                7 * day
            )
        ]

        for (attempt, expectedDelay) in cases {
            let dueAt = try #require(schedule.execute(attempts: [attempt]))
            #expect(dueAt == start.addingTimeInterval(expectedDelay))
        }

        let secondCorrect = makeAttempt(
            idByte: 2,
            skillID: skillID,
            outcome: .correct,
            at: start.addingTimeInterval(day)
        )
        #expect(
            schedule.execute(attempts: [cases[1].0, secondCorrect])
                == secondCorrect.recordedAt.addingTimeInterval(3 * day)
        )
    }

    @Test
    func delayedRecallAndChallengeEvidenceProduceProficientThenMastered() {
        let skillID = SkillID(rawValue: "skill.one")
        let start = Date(timeIntervalSince1970: 10_000)
        let guided = makeAttempt(skillID: skillID, outcome: .correct, at: start)
        let recallOne = makeAttempt(
            idByte: 2,
            skillID: skillID,
            activityID: .review(skillID: skillID),
            outcome: .correct,
            at: start.addingTimeInterval(day)
        )
        let recallTwo = makeAttempt(
            idByte: 3,
            skillID: skillID,
            activityID: .review(skillID: skillID),
            outcome: .correct,
            at: start.addingTimeInterval(2 * day)
        )
        let proficient = CalculateSkillMasteryUseCase().execute(
            skillID: skillID,
            attempts: [guided, recallOne, recallTwo],
            now: start.addingTimeInterval(2 * day)
        )

        #expect(proficient.level == .proficient)

        let guidedTwo = makeAttempt(
            idByte: 4,
            skillID: skillID,
            outcome: .correct,
            at: start.addingTimeInterval(4 * day)
        )
        let challenge = makeAttempt(
            idByte: 5,
            skillID: skillID,
            activityID: .challenge(skillID: skillID),
            outcome: .correct,
            at: start.addingTimeInterval(7 * day)
        )
        let mastered = CalculateSkillMasteryUseCase().execute(
            skillID: skillID,
            attempts: [guided, recallOne, recallTwo, guidedTwo, challenge],
            now: challenge.recordedAt
        )

        #expect(mastered.level == .mastered)
    }

    @Test
    func queueFiltersByInjectedClockAndOrdersOverdueBeforeDue() throws {
        let now = Date(timeIntervalSince1970: 10 * day)
        let fixture = makeFixture(
            attempts: [
                makeAttempt(
                    skillID: SkillID(rawValue: "skill.one"),
                    outcome: .incorrect,
                    at: now.addingTimeInterval(-2 * day)
                ),
                makeAttempt(
                    idByte: 2,
                    skillID: SkillID(rawValue: "skill.two"),
                    outcome: .incorrect,
                    at: now
                ),
                makeAttempt(
                    idByte: 3,
                    skillID: SkillID(rawValue: "skill.future"),
                    outcome: .correct,
                    at: now
                )
            ],
            now: now
        )

        let queue = try fixture.loadQueue.execute()

        #expect(queue.map(\.id.rawValue) == ["skill.one", "skill.two"])
        #expect(queue.map(\.status) == [.overdue, .due])
    }

    @Test
    func mistakeNotebookGroupsIncorrectAttemptsStably() throws {
        let now = Date(timeIntervalSince1970: 20 * day)
        let fixture = makeFixture(
            attempts: [
                makeAttempt(
                    skillID: SkillID(rawValue: "skill.one"),
                    outcome: .incorrect,
                    at: now.addingTimeInterval(-day)
                ),
                makeAttempt(
                    idByte: 2,
                    skillID: SkillID(rawValue: "skill.one"),
                    outcome: .incorrect,
                    errorCategory: .syntax,
                    at: now
                ),
                makeAttempt(
                    idByte: 3,
                    skillID: SkillID(rawValue: "skill.two"),
                    outcome: .correct,
                    at: now
                )
            ],
            now: now
        )

        let notebook = try fixture.loadMistakes.execute()

        #expect(notebook.map(\.id.rawValue) == ["skill.one"])
        #expect(notebook[0].attempts.count == 2)
        #expect(notebook[0].latestErrorCategory == .syntax)
    }

    @Test
    func correctReviewRecordsRecallEvidenceAndClearsDueQueue() throws {
        let now = Date(timeIntervalSince1970: 30 * day)
        let fixture = makeFixture(
            attempts: [
                makeAttempt(
                    skillID: SkillID(rawValue: "skill.one"),
                    outcome: .incorrect,
                    at: now.addingTimeInterval(-day)
                )
            ],
            now: now
        )

        let result = try fixture.completeReview.execute(
            skillID: SkillID(rawValue: "skill.one"),
            choiceID: "correct"
        )

        #expect(result.isCorrect)
        #expect(fixture.attempts.attempts.count == 2)
        #expect(
            fixture.attempts.attempts.last?.evidence.activityID
                == .review(skillID: SkillID(rawValue: "skill.one"))
        )
        #expect(try fixture.loadQueue.execute().isEmpty)
    }

    @Test
    func reviewAndMistakeViewModelsExposeContentCompletionEmptyAndFailureStates() {
        let now = Date(timeIntervalSince1970: 40 * day)
        let dueFixture = makeFixture(
            attempts: [
                makeAttempt(
                    skillID: SkillID(rawValue: "skill.one"),
                    outcome: .incorrect,
                    at: now
                )
            ],
            now: now
        )
        let review = ReviewQueueViewModel(
            loadReviewQueue: dueFixture.loadQueue,
            completeReview: dueFixture.completeReview
        )
        let mistakes = MistakeNotebookViewModel(
            loadMistakes: dueFixture.loadMistakes
        )

        review.load()
        mistakes.load()
        #expect(review.loadState == .loaded)
        #expect(review.currentItem?.id == SkillID(rawValue: "skill.one"))
        #expect(mistakes.entries.count == 1)

        review.selectChoice("correct")
        review.submit(skillID: SkillID(rawValue: "skill.one"))
        #expect(review.isSessionComplete)
        #expect(review.items.isEmpty)

        let emptyFixture = makeFixture(attempts: [], now: now)
        let empty = ReviewQueueViewModel(
            loadReviewQueue: emptyFixture.loadQueue,
            completeReview: emptyFixture.completeReview
        )
        empty.load()
        #expect(empty.loadState == .loaded)
        #expect(empty.summary == "No reviews due")

        let failedFixture = makeFixture(
            attempts: [],
            now: now,
            loadError: ReviewFixtureError.unavailable
        )
        let failedReview = ReviewQueueViewModel(
            loadReviewQueue: failedFixture.loadQueue,
            completeReview: failedFixture.completeReview
        )
        let failedMistakes = MistakeNotebookViewModel(
            loadMistakes: failedFixture.loadMistakes
        )
        failedReview.load()
        failedMistakes.load()
        #expect(failedReview.loadState == .failed("Review history unavailable"))
        #expect(failedMistakes.loadState == .failed("Review history unavailable"))
    }

    private func makeFixture(
        attempts: [LearningAttempt],
        now: Date,
        loadError: (any Error)? = nil
    ) -> ReviewFixture {
        let catalog = LearningCatalog(
            sourceID: "fixture",
            editionTitle: "Fixture",
            levels: [
                LearningLevel(
                    id: "level.one",
                    title: "Level",
                    summary: "Summary",
                    lessons: [
                        makeLesson(id: "skill.one"),
                        makeLesson(id: "skill.two"),
                        makeLesson(id: "skill.future")
                    ]
                )
            ]
        )
        let content = ReviewContentRepository(catalog: catalog)
        let skills = catalog.lessons.map { lesson in
            let skillID = SkillID(rawValue: lesson.id)
            return CanonicalSkill(
                id: skillID,
                title: lesson.title,
                lessonIDs: [lesson.id],
                activityIDs: [lesson.activityID, .review(skillID: skillID)]
            )
        }
        let skillRepository = ReviewSkillRepository(skills: skills)
        let attemptRepository = ReviewAttemptRepository(
            attempts: attempts,
            loadError: loadError
        )
        let clock = ReviewClock(now: now)
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: skillRepository
        )
        let loadQueue = LoadReviewQueueUseCase(
            contentRepository: content,
            loadCanonicalSkills: loadSkills,
            attemptRepository: attemptRepository,
            clock: clock
        )
        let record = RecordLearningAttemptUseCase(
            loadCanonicalSkills: loadSkills,
            attemptRepository: attemptRepository,
            clock: clock,
            idGenerator: ReviewIDGenerator()
        )
        return ReviewFixture(
            attempts: attemptRepository,
            loadQueue: loadQueue,
            completeReview: CompleteReviewUseCase(
                loadReviewQueue: loadQueue,
                recordAttempt: record
            ),
            loadMistakes: LoadMistakeNotebookUseCase(
                loadCanonicalSkills: loadSkills,
                attemptRepository: attemptRepository
            )
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

    private func makeAttempt(
        idByte: UInt8 = 1,
        skillID: SkillID,
        activityID: LearningActivityID? = nil,
        outcome: AttemptOutcome,
        errorCategory: LearningErrorCategory? = nil,
        at date: Date
    ) -> LearningAttempt {
        LearningAttempt(
            id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, idByte)),
            evidence: LearningEvidence(
                lessonID: skillID.rawValue,
                skillID: skillID,
                activityID: activityID ?? LearningActivityID(rawValue: skillID.rawValue),
                outcome: outcome,
                errorCategory: outcome == .correct
                    ? nil
                    : errorCategory ?? .incorrectChoice
            ),
            recordedAt: date
        )
    }
}

@MainActor
private struct ReviewFixture {
    let attempts: ReviewAttemptRepository
    let loadQueue: LoadReviewQueueUseCase
    let completeReview: CompleteReviewUseCase
    let loadMistakes: LoadMistakeNotebookUseCase
}

@MainActor
private final class ReviewContentRepository: LearningContentRepository {
    let catalog: LearningCatalog

    init(catalog: LearningCatalog) {
        self.catalog = catalog
    }

    func loadCatalog() -> LearningCatalog {
        catalog
    }
}

@MainActor
private final class ReviewSkillRepository: CanonicalSkillRepository {
    let skills: [CanonicalSkill]

    init(skills: [CanonicalSkill]) {
        self.skills = skills
    }

    func loadCanonicalSkills() -> [CanonicalSkill] {
        skills
    }
}

@MainActor
private final class ReviewAttemptRepository: LearningAttemptRepository {
    private(set) var attempts: [LearningAttempt]
    private let loadError: (any Error)?

    init(attempts: [LearningAttempt], loadError: (any Error)? = nil) {
        self.attempts = attempts
        self.loadError = loadError
    }

    func record(_ attempt: LearningAttempt) {
        attempts.append(attempt)
    }

    func loadAttempts(skillID: SkillID) throws -> [LearningAttempt] {
        if let loadError { throw loadError }
        return attempts.filter { $0.evidence.skillID == skillID }
    }

    func loadAllAttempts() throws -> [LearningAttempt] {
        if let loadError { throw loadError }
        return attempts
    }
}

@MainActor
private struct ReviewClock: LearningClock {
    let now: Date
}

@MainActor
private final class ReviewIDGenerator: LearningAttemptIDGenerating {
    private var byte: UInt8 = 100

    func next() -> UUID {
        defer { byte &+= 1 }
        return UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, byte))
    }
}

private enum ReviewFixtureError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Review history unavailable"
    }
}
