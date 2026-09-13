import Foundation

@MainActor
final class UserDefaultsLearningSyncRepository:
    LearningSyncRepository,
    LearningSyncResetGenerationAdopting {
    private static let snapshotKey = "swiftLearn.watch.sync.snapshot.v1"
    private static let pendingEventsKey = "swiftLearn.watch.sync.pending.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSnapshot() throws -> LearningSyncSnapshot {
        guard let data = defaults.data(forKey: Self.snapshotKey) else {
            return .empty
        }
        let snapshot = try JSONDecoder().decode(LearningSyncSnapshot.self, from: data)
        guard snapshot.schemaVersion == LearningSyncSnapshot.currentSchemaVersion else {
            throw LearningSyncDomainError.unsupportedSnapshotSchema(
                snapshot.schemaVersion
            )
        }
        return snapshot
    }

    func saveSnapshot(_ snapshot: LearningSyncSnapshot) throws {
        guard snapshot.schemaVersion == LearningSyncSnapshot.currentSchemaVersion else {
            throw LearningSyncDomainError.unsupportedSnapshotSchema(
                snapshot.schemaVersion
            )
        }
        defaults.set(try JSONEncoder().encode(snapshot), forKey: Self.snapshotKey)
    }

    func loadPendingEvents() throws -> [LearningSyncEvent] {
        guard let data = defaults.data(forKey: Self.pendingEventsKey) else {
            return []
        }
        return try JSONDecoder().decode([LearningSyncEvent].self, from: data)
    }

    func enqueue(_ event: LearningSyncEvent) throws {
        var events = try loadPendingEvents()
        guard events.contains(where: { $0.id == event.id }) == false else {
            return
        }
        events.append(event)
        try savePendingEvents(events)
    }

    func removePendingEvents(ids: Set<UUID>) throws {
        guard ids.isEmpty == false else { return }
        try savePendingEvents(
            loadPendingEvents().filter { ids.contains($0.id) == false }
        )
    }

    func adoptResetGeneration(_ generation: Int) throws {
        let snapshot = try loadSnapshot()
        guard generation > snapshot.resetGeneration else { return }

        try saveSnapshot(
            LearningSyncSnapshot(
                resetGeneration: generation,
                completedLessonIDs: [],
                attempts: [],
                appliedEventIDs: []
            )
        )
        try savePendingEvents(
            loadPendingEvents().filter { $0.resetGeneration >= generation }
        )
    }

    private func savePendingEvents(_ events: [LearningSyncEvent]) throws {
        defaults.set(
            try JSONEncoder().encode(events),
            forKey: Self.pendingEventsKey
        )
    }
}
