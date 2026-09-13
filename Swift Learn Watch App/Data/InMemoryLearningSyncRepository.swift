import Foundation

@MainActor
final class InMemoryLearningSyncRepository: LearningSyncRepository {
    private var snapshot: LearningSyncSnapshot
    private var pendingEvents: [LearningSyncEvent]

    init(
        snapshot: LearningSyncSnapshot = .empty,
        pendingEvents: [LearningSyncEvent] = []
    ) {
        self.snapshot = snapshot
        self.pendingEvents = pendingEvents
    }

    func loadSnapshot() -> LearningSyncSnapshot { snapshot }

    func saveSnapshot(_ snapshot: LearningSyncSnapshot) {
        self.snapshot = snapshot
    }

    func loadPendingEvents() -> [LearningSyncEvent] { pendingEvents }

    func enqueue(_ event: LearningSyncEvent) {
        guard pendingEvents.contains(where: { $0.id == event.id }) == false else {
            return
        }
        pendingEvents.append(event)
    }

    func removePendingEvents(ids: Set<UUID>) {
        pendingEvents.removeAll { ids.contains($0.id) }
    }
}
