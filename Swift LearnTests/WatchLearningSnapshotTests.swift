import Foundation
import Testing
@testable import Swift_Learn

@MainActor
struct WatchLearningSnapshotTests {
    @Test
    func snapshotCombinesProfileProgressReviewAndNextLesson() throws {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let catalog = makeCatalog()
        let content = WatchTestContentRepository(catalog: catalog)
        let progress = WatchTestProgressRepository(completedLessonIDs: ["lesson.one"])
        let profile = WatchTestProfileRepository(
            profile: LearnerProfile(
                displayName: "Ahmed",
                avatar: .man,
                appearance: .system
            )
        )
        let skillID = SkillID(rawValue: "skill.one")
        let attempts = WatchTestAttemptRepository(
            attempts: [
                LearningAttempt(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    evidence: LearningEvidence(
                        lessonID: "lesson.one",
                        skillID: skillID,
                        activityID: LearningActivityID(rawValue: "lesson.one"),
                        outcome: .incorrect,
                        errorCategory: .incorrectChoice
                    ),
                    recordedAt: now
                )
            ]
        )
        let loadCanonicalSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: WatchTestSkillRepository(
                skills: [
                    CanonicalSkill(
                        id: skillID,
                        title: "Foundations",
                        lessonIDs: ["lesson.one", "lesson.two"],
                        activityIDs: [
                            LearningActivityID(rawValue: "lesson.one"),
                            LearningActivityID(rawValue: "lesson.two"),
                            .review(skillID: skillID)
                        ]
                    )
                ]
            )
        )
        let clock = WatchTestClock(now: now)
        let useCase = CreateWatchLearningSnapshotUseCase(
            loadJourney: LoadLearningJourneyUseCase(
                contentRepository: content,
                progressRepository: progress
            ),
            loadProfile: LoadLearnerProfileUseCase(
                contentRepository: content,
                progressRepository: progress,
                profileRepository: profile
            ),
            loadReviewQueue: LoadReviewQueueUseCase(
                contentRepository: content,
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attempts,
                clock: clock
            ),
            loadSyncSnapshot: LoadLearningSyncSnapshotUseCase(
                repository: WatchTestSyncRepository()
            ),
            loadMasteryOverview: LoadMasteryOverviewUseCase(
                loadCanonicalSkills: loadCanonicalSkills,
                attemptRepository: attempts,
                clock: clock
            ),
            clock: clock
        )

        let snapshot = try useCase.execute()

        #expect(snapshot.learnerName == "Ahmed")
        #expect(snapshot.completedLessonCount == 1)
        #expect(snapshot.totalLessonCount == 2)
        #expect(snapshot.dueReviewCount == 1)
        #expect(snapshot.reviewItems.count == 1)
        #expect(snapshot.reviewItems.first?.skillID == "skill.one")
        #expect(snapshot.reviewItems.first?.lessonID == "lesson.one")
        #expect(snapshot.reviewItems.first?.activityID == "review.skill.one")
        #expect(snapshot.reviewItems.first?.correctChoiceID == "let")
        #expect(snapshot.reviewItems.first?.choices.map(\.id) == ["let", "var"])
        #expect(snapshot.nextLesson?.id == "lesson.two")
        #expect(snapshot.nextLesson?.title == "Variables")
        #expect(snapshot.resetGeneration == 0)
        #expect(snapshot.acknowledgedEventIDs.isEmpty)
        #expect(snapshot.generatedAt == now)
        #expect(snapshot.progress == 0.5)
        let detail = try #require(snapshot.progressDetail)
        #expect(detail.levelTitle == "Foundations")
        #expect(detail.levelCompletedLessonCount == 1)
        #expect(detail.levelTotalLessonCount == 2)
        #expect(detail.trackedSkillCount == 1)
        #expect(detail.proficientSkillCount == 0)
        #expect(detail.masteredSkillCount == 0)
        #expect(detail.levelProgress == 0.5)
    }

    @Test
    func wireFormatRoundTripsCurrentSchema() throws {
        let snapshot = WatchLearningSnapshot(
            learnerName: "Swift Learner",
            completedLessonCount: 3,
            totalLessonCount: 10,
            dueReviewCount: 2,
            reviewItems: [makeReviewSnapshot()],
            nextLesson: WatchNextLessonSnapshot(
                id: "lesson.four",
                title: "Optionals",
                objective: "Practice safe optional handling."
            ),
            generatedAt: Date(timeIntervalSince1970: 123)
        )

        let decoded = try WatchLearningSnapshotWireFormat.decode(
            WatchLearningSnapshotWireFormat.encode(snapshot)
        )

        #expect(decoded == snapshot)
    }

    @Test
    func wireFormatRejectsUnknownSchema() throws {
        let snapshot = WatchLearningSnapshot(
            schemaVersion: 99,
            learnerName: "Swift Learner",
            completedLessonCount: 0,
            totalLessonCount: 0,
            dueReviewCount: 0,
            nextLesson: nil,
            generatedAt: .distantPast
        )
        let data = try JSONEncoder().encode(snapshot)

        #expect(throws: WatchLearningSnapshotWireError.unsupportedSchema(99)) {
            try WatchLearningSnapshotWireFormat.decode(data)
        }
    }

    @Test
    func wireFormatReadsLegacySnapshotWithoutResetGeneration() throws {
        let snapshot = WatchLearningSnapshot(
            schemaVersion: 1,
            learnerName: "Swift Learner",
            completedLessonCount: 1,
            totalLessonCount: 2,
            dueReviewCount: 0,
            nextLesson: nil,
            generatedAt: Date(timeIntervalSince1970: 123)
        )
        let encoded = try JSONEncoder().encode(snapshot)
        var payload = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        payload.removeValue(forKey: "resetGeneration")
        payload.removeValue(forKey: "acknowledgedEventIDs")
        payload.removeValue(forKey: "reviewItems")

        let decoded = try WatchLearningSnapshotWireFormat.decode(
            JSONSerialization.data(withJSONObject: payload)
        )

        #expect(decoded.schemaVersion == 1)
        #expect(decoded.resetGeneration == 0)
        #expect(decoded.acknowledgedEventIDs.isEmpty)
        #expect(decoded.reviewItems.isEmpty)
        #expect(decoded.progressDetail == nil)
    }

    @Test
    func wireFormatRoundTripsProgressDetailAndReadsSnapshotWithoutIt() throws {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let snapshot = WatchLearningSnapshot(
            learnerName: "Ahmed",
            completedLessonCount: 12,
            totalLessonCount: 486,
            dueReviewCount: 2,
            progressDetail: WatchProgressDetailSnapshot(
                levelTitle: "Foundations",
                levelCompletedLessonCount: 12,
                levelTotalLessonCount: 53,
                trackedSkillCount: 20,
                proficientSkillCount: 5,
                masteredSkillCount: 2
            ),
            nextLesson: nil,
            generatedAt: now
        )

        let decoded = try WatchLearningSnapshotWireFormat.decode(
            WatchLearningSnapshotWireFormat.encode(snapshot)
        )

        #expect(decoded == snapshot)
        #expect(decoded.schemaVersion == 4)
        #expect(decoded.progressDetail?.levelProgress == Double(12) / Double(53))

        let withoutDetail = WatchLearningSnapshot(
            schemaVersion: 3,
            learnerName: "Ahmed",
            completedLessonCount: 12,
            totalLessonCount: 486,
            dueReviewCount: 2,
            nextLesson: nil,
            generatedAt: now
        )

        let decodedLegacy = try WatchLearningSnapshotWireFormat.decode(
            WatchLearningSnapshotWireFormat.encode(withoutDetail)
        )

        #expect(decodedLegacy.progressDetail == nil)
        #expect(decodedLegacy.schemaVersion == 3)
    }

    @Test
    func snapshotCreationPropagatesJourneyFailure() {
        let catalog = makeCatalog()
        let content = WatchTestContentRepository(catalog: catalog)
        let failingProgress = WatchFailingProgressRepository()
        let profile = WatchTestProfileRepository(profile: .defaultProfile)
        let skills = WatchTestSkillRepository(skills: [])
        let attempts = WatchTestAttemptRepository()
        let clock = WatchTestClock(now: .distantPast)
        let useCase = CreateWatchLearningSnapshotUseCase(
            loadJourney: LoadLearningJourneyUseCase(
                contentRepository: content,
                progressRepository: failingProgress
            ),
            loadProfile: LoadLearnerProfileUseCase(
                contentRepository: content,
                progressRepository: failingProgress,
                profileRepository: profile
            ),
            loadReviewQueue: LoadReviewQueueUseCase(
                contentRepository: content,
                loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                    contentRepository: content,
                    skillRepository: skills
                ),
                attemptRepository: attempts,
                clock: clock
            ),
            loadSyncSnapshot: LoadLearningSyncSnapshotUseCase(
                repository: WatchTestSyncRepository()
            ),
            loadMasteryOverview: LoadMasteryOverviewUseCase(
                loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                    contentRepository: content,
                    skillRepository: skills
                ),
                attemptRepository: attempts,
                clock: clock
            ),
            clock: clock
        )

        #expect(throws: WatchSnapshotFixtureError.progressUnavailable) {
            try useCase.execute()
        }
    }

    private func makeCatalog() -> LearningCatalog {
        LearningCatalog(
            sourceID: "watch-test",
            editionTitle: "Watch Test",
            levels: [
                LearningLevel(
                    id: "level.one",
                    title: "Foundations",
                    summary: "Test level",
                    lessons: [
                        makeLesson(id: "lesson.one", title: "Constants"),
                        makeLesson(id: "lesson.two", title: "Variables")
                    ]
                )
            ]
        )
    }

    private func makeLesson(id: String, title: String) -> LearningLesson {
        LearningLesson(
            id: id,
            title: title,
            objective: "Learn \(title.lowercased()).",
            instruction: "Choose the correct answer.",
            codePrefix: "",
            codeSuffix: " value = 1",
            choices: [
                LearningChoice(id: "let", code: "let"),
                LearningChoice(id: "var", code: "var")
            ],
            correctChoiceID: "let",
            correctFeedback: "Correct",
            incorrectFeedback: "Try again",
            sourceTitle: "Swift",
            sourceReferences: []
        )
    }

    private func makeReviewSnapshot() -> WatchReviewItemSnapshot {
        WatchReviewItemSnapshot(
            skillID: "skill.one",
            lessonID: "lesson.one",
            activityID: "review.skill.one",
            title: "Constants",
            prompt: "Choose the constant declaration.",
            choices: [
                WatchReviewChoiceSnapshot(id: "let", text: "let"),
                WatchReviewChoiceSnapshot(id: "var", text: "var")
            ],
            correctChoiceID: "let",
            correctFeedback: "Correct",
            incorrectFeedback: "Try again"
        )
    }
}

@MainActor
private final class WatchTestContentRepository: LearningContentRepository {
    let catalog: LearningCatalog

    init(catalog: LearningCatalog) {
        self.catalog = catalog
    }

    func loadCatalog() -> LearningCatalog { catalog }
}

@MainActor
private final class WatchTestProgressRepository: LearningProgressRepository {
    private var completedLessonIDs: Set<String>

    init(completedLessonIDs: Set<String>) {
        self.completedLessonIDs = completedLessonIDs
    }

    func loadCompletedLessonIDs() -> Set<String> { completedLessonIDs }

    func markCompleted(lessonID: String) {
        completedLessonIDs.insert(lessonID)
    }
}

@MainActor
private struct WatchFailingProgressRepository: LearningProgressRepository {
    func loadCompletedLessonIDs() throws -> Set<String> {
        throw WatchSnapshotFixtureError.progressUnavailable
    }

    func markCompleted(lessonID: String) throws {
        throw WatchSnapshotFixtureError.progressUnavailable
    }
}

@MainActor
private final class WatchTestProfileRepository: LearnerProfileRepository {
    private var profile: LearnerProfile

    init(profile: LearnerProfile) {
        self.profile = profile
    }

    func loadProfile() -> LearnerProfile { profile }

    func saveProfile(_ profile: LearnerProfile) {
        self.profile = profile
    }
}

@MainActor
private struct WatchTestSkillRepository: CanonicalSkillRepository {
    let skills: [CanonicalSkill]

    func loadCanonicalSkills() -> [CanonicalSkill] { skills }
}

@MainActor
private final class WatchTestAttemptRepository: LearningAttemptRepository {
    private var attempts: [LearningAttempt]

    init(attempts: [LearningAttempt] = []) {
        self.attempts = attempts
    }

    func record(_ attempt: LearningAttempt) {
        attempts.append(attempt)
    }

    func loadAttempts(skillID: SkillID) -> [LearningAttempt] {
        attempts.filter { $0.evidence.skillID == skillID }
    }

    func loadAllAttempts() -> [LearningAttempt] { attempts }
}

@MainActor
private final class WatchTestSyncRepository: LearningSyncRepository {
    private var snapshot: LearningSyncSnapshot = .empty
    private var pendingEvents: [LearningSyncEvent] = []

    func loadSnapshot() -> LearningSyncSnapshot { snapshot }

    func saveSnapshot(_ snapshot: LearningSyncSnapshot) {
        self.snapshot = snapshot
    }

    func loadPendingEvents() -> [LearningSyncEvent] { pendingEvents }

    func enqueue(_ event: LearningSyncEvent) {
        pendingEvents.append(event)
    }

    func removePendingEvents(ids: Set<UUID>) {
        pendingEvents.removeAll { ids.contains($0.id) }
    }
}

@MainActor
private struct WatchTestClock: LearningClock {
    let now: Date
}

private enum WatchSnapshotFixtureError: Error, Equatable {
    case progressUnavailable
}
