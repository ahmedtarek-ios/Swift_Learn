import Foundation
import SwiftData
import Testing
@testable import Swift_Learn

@MainActor
struct LearningSyncTests {
    private let eventID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000001"
    )!
    private let attemptID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000002"
    )!
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test
    func mergeUnionsLessonsAndDeduplicatesAttemptsAndEvents() throws {
        let event = makeAttemptEvent()
        let local = LearningSyncSnapshot(
            resetGeneration: 0,
            completedLessonIDs: ["lesson.one"],
            attempts: [],
            appliedEventIDs: []
        )

        let first = try MergeLearningSyncUseCase().execute(
            local: local,
            incoming: [
                makeLessonEvent(id: eventID, lessonID: "lesson.two"),
                event,
                event
            ]
        )

        #expect(first.snapshot.completedLessonIDs == ["lesson.one", "lesson.two"])
        #expect(first.snapshot.attempts.count == 1)
        #expect(first.appliedEventIDs.count == 2)
        #expect(first.ignoredEventIDs == [event.id])

        let repeated = try MergeLearningSyncUseCase().execute(
            local: first.snapshot,
            incoming: [event]
        )
        #expect(repeated.snapshot.attempts.count == 1)
        #expect(repeated.appliedEventIDs.isEmpty)
        #expect(repeated.ignoredEventIDs == [event.id])
    }

    @Test
    func newerResetClearsOldProgressBeforeSameGenerationEvents() throws {
        let resetID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000003"
        )!
        let lessonID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000004"
        )!
        let local = LearningSyncSnapshot(
            resetGeneration: 1,
            completedLessonIDs: ["lesson.old"],
            attempts: [makeAttempt()],
            appliedEventIDs: [eventID]
        )
        let postResetLesson = LearningSyncEvent(
            id: lessonID,
            deviceID: "watch",
            resetGeneration: 2,
            createdAt: now.addingTimeInterval(-10),
            kind: .lessonCompleted,
            lessonID: "lesson.new"
        )
        let reset = LearningSyncEvent(
            id: resetID,
            deviceID: "phone",
            resetGeneration: 2,
            createdAt: now,
            kind: .progressReset
        )

        let result = try MergeLearningSyncUseCase().execute(
            local: local,
            incoming: [postResetLesson, reset]
        )

        #expect(result.snapshot.resetGeneration == 2)
        #expect(result.snapshot.completedLessonIDs == ["lesson.new"])
        #expect(result.snapshot.attempts.isEmpty)
        #expect(result.snapshot.appliedEventIDs == [resetID, lessonID])
    }

    @Test
    func staleGenerationCannotRestoreResetProgress() throws {
        let local = LearningSyncSnapshot(
            resetGeneration: 2,
            completedLessonIDs: [],
            attempts: [],
            appliedEventIDs: []
        )
        let stale = LearningSyncEvent(
            id: eventID,
            deviceID: "watch",
            resetGeneration: 1,
            createdAt: now,
            kind: .lessonCompleted,
            lessonID: "lesson.old"
        )

        let result = try MergeLearningSyncUseCase().execute(
            local: local,
            incoming: [stale]
        )

        #expect(result.snapshot.completedLessonIDs.isEmpty)
        #expect(result.appliedEventIDs.isEmpty)
        #expect(result.ignoredEventIDs == [eventID])
    }

    @Test
    func generationCannotAdvanceWithoutResetEvent() {
        let event = LearningSyncEvent(
            id: eventID,
            deviceID: "watch",
            resetGeneration: 1,
            createdAt: now,
            kind: .lessonCompleted,
            lessonID: "lesson.one"
        )

        #expect(
            throws: LearningSyncDomainError.generationAdvanceRequiresReset(1)
        ) {
            try MergeLearningSyncUseCase().execute(
                local: .empty,
                incoming: [event]
            )
        }
    }

    @Test
    func wireFormatRoundTripsAndRejectsUnsupportedSchema() throws {
        let event = makeAttemptEvent()
        #expect(
            try LearningSyncWireFormat.decodeEvent(
                LearningSyncWireFormat.encode(event)
            ) == event
        )

        let unsupported = LearningSyncEvent(
            schemaVersion: 99,
            id: eventID,
            deviceID: "watch",
            resetGeneration: 0,
            createdAt: now,
            kind: .progressReset
        )
        let data = try JSONEncoder().encode(unsupported)
        #expect(throws: LearningSyncDomainError.unsupportedEventSchema(99)) {
            try LearningSyncWireFormat.decodeEvent(data)
        }
    }

    @Test
    func phoneValidationAcceptsCanonicalReviewAndRejectsCompanionReset() throws {
        let content = BundledLearningContentRepository(
            bundle: Bundle(for: AppContainer.self)
        )
        let skills = ContentCanonicalSkillRepository(contentRepository: content)
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: skills
        )
        let validator = ValidateLearningSyncEventUseCase(
            contentRepository: content,
            loadCanonicalSkills: loadSkills
        )
        let lesson = try #require(content.loadCatalog().lessons.first)
        let review = LearningSyncEvent(
            id: eventID,
            deviceID: "watch",
            resetGeneration: 0,
            createdAt: now,
            kind: .attemptRecorded,
            attempt: LearningSyncAttempt(
                id: attemptID,
                lessonID: lesson.id,
                skillID: lesson.id,
                activityID: "review.\(lesson.id)",
                outcome: .correct,
                errorCategory: nil,
                recordedAt: now
            )
        )

        #expect(throws: Never.self) {
            try validator.validate(review)
        }
        #expect(throws: LearningSyncValidationError.companionResetNotAllowed) {
            try validator.validate(
                LearningSyncEvent(
                    id: attemptID,
                    deviceID: "watch",
                    resetGeneration: 1,
                    createdAt: now,
                    kind: .progressReset
                )
            )
        }
    }

    @Test
    func swiftDataRepositoryPersistsMergeAndResetGeneration() throws {
        let container = try AppContainer(isStoredInMemoryOnly: true)
        let repository = SwiftDataLearningSyncRepository(
            modelContext: container.modelContainer.mainContext
        )
        let merge = MergeLearningSyncEventsUseCase(
            repository: repository,
            validator: AcceptAllLearningSyncEventsValidator()
        )

        _ = try merge.execute([
            makeLessonEvent(id: eventID, lessonID: "lesson.one"),
            makeAttemptEvent()
        ])
        let stored = try repository.loadSnapshot()
        #expect(stored.completedLessonIDs == ["lesson.one"])
        #expect(stored.attempts.map(\.id) == [attemptID])

        try SwiftDataLearningResetRepository(
            modelContext: container.modelContainer.mainContext,
            syncGeneration: repository
        ).resetLearningProgress()
        let reset = try repository.loadSnapshot()
        #expect(reset.resetGeneration == 1)
        #expect(reset.completedLessonIDs.isEmpty)
        #expect(reset.attempts.isEmpty)

        _ = try merge.execute([
            makeLessonEvent(
                id: UUID(
                    uuidString: "00000000-0000-0000-0000-000000000005"
                )!,
                lessonID: "lesson.stale",
                generation: 0
            )
        ])
        #expect(try repository.loadSnapshot().completedLessonIDs.isEmpty)
    }

    private func makeLessonEvent(
        id: UUID,
        lessonID: String,
        generation: Int = 0
    ) -> LearningSyncEvent {
        LearningSyncEvent(
            id: id,
            deviceID: "watch",
            resetGeneration: generation,
            createdAt: now,
            kind: .lessonCompleted,
            lessonID: lessonID
        )
    }

    private func makeAttemptEvent() -> LearningSyncEvent {
        LearningSyncEvent(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            deviceID: "watch",
            resetGeneration: 0,
            createdAt: now,
            kind: .attemptRecorded,
            attempt: makeAttempt()
        )
    }

    private func makeAttempt() -> LearningSyncAttempt {
        LearningSyncAttempt(
            id: attemptID,
            lessonID: "lesson.one",
            skillID: "skill.one",
            activityID: "review.skill.one",
            outcome: .correct,
            errorCategory: nil,
            recordedAt: now
        )
    }
}

@MainActor
private struct AcceptAllLearningSyncEventsValidator: LearningSyncEventValidating {
    func validate(_ event: LearningSyncEvent) {}
}
