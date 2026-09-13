import Foundation
import Testing
@testable import Swift_Learn_Watch_App

@MainActor
struct LearningSyncRepositoryTests {
    @Test
    func pendingEventsPersistOnceAndCanBeAcknowledged() throws {
        let suiteName = "watch-sync-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsLearningSyncRepository(defaults: defaults)
        let event = makeEvent(generation: 0)

        try repository.enqueue(event)
        try repository.enqueue(event)
        #expect(try repository.loadPendingEvents() == [event])

        try repository.removePendingEvents(ids: [event.id])
        #expect(try repository.loadPendingEvents().isEmpty)
    }

    @Test
    func adoptingNewResetDropsStaleSnapshotAndQueuedEvents() throws {
        let suiteName = "watch-sync-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsLearningSyncRepository(defaults: defaults)
        let staleEvent = makeEvent(generation: 0)
        let currentEvent = makeEvent(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            generation: 2
        )
        try repository.saveSnapshot(
            LearningSyncSnapshot(
                resetGeneration: 0,
                completedLessonIDs: ["lesson.old"],
                attempts: [],
                appliedEventIDs: []
            )
        )
        try repository.enqueue(staleEvent)
        try repository.enqueue(currentEvent)

        try repository.adoptResetGeneration(2)

        let snapshot = try repository.loadSnapshot()
        #expect(snapshot.resetGeneration == 2)
        #expect(snapshot.completedLessonIDs.isEmpty)
        #expect(try repository.loadPendingEvents() == [currentEvent])
    }

    private func makeEvent(
        id: UUID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!,
        generation: Int
    ) -> LearningSyncEvent {
        LearningSyncEvent(
            id: id,
            deviceID: "watch",
            resetGeneration: generation,
            createdAt: Date(timeIntervalSince1970: 2_000_000_000),
            kind: .lessonCompleted,
            lessonID: "lesson.one"
        )
    }
}
