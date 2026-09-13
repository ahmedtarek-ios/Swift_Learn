import Foundation

enum LearningSyncEventKind: String, Codable, Equatable, Sendable {
    case lessonCompleted
    case attemptRecorded
    case progressReset
}

enum LearningSyncAttemptOutcome: String, Codable, Equatable, Sendable {
    case correct
    case incorrect
}

enum LearningSyncErrorCategory: String, Codable, Equatable, Sendable {
    case incorrectChoice
    case syntax
    case typeMismatch
    case logic
    case testFailure
    case architectureBoundary
}

struct LearningSyncAttempt: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let lessonID: String
    let skillID: String
    let activityID: String
    let outcome: LearningSyncAttemptOutcome
    let errorCategory: LearningSyncErrorCategory?
    let recordedAt: Date
}

struct LearningSyncEvent: Codable, Equatable, Identifiable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let id: UUID
    let deviceID: String
    let resetGeneration: Int
    let createdAt: Date
    let kind: LearningSyncEventKind
    let lessonID: String?
    let attempt: LearningSyncAttempt?

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        id: UUID,
        deviceID: String,
        resetGeneration: Int,
        createdAt: Date,
        kind: LearningSyncEventKind,
        lessonID: String? = nil,
        attempt: LearningSyncAttempt? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.deviceID = deviceID
        self.resetGeneration = resetGeneration
        self.createdAt = createdAt
        self.kind = kind
        self.lessonID = lessonID
        self.attempt = attempt
    }
}

struct LearningSyncSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let resetGeneration: Int
    let completedLessonIDs: Set<String>
    let attempts: [LearningSyncAttempt]
    let appliedEventIDs: Set<UUID>

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        resetGeneration: Int,
        completedLessonIDs: Set<String>,
        attempts: [LearningSyncAttempt],
        appliedEventIDs: Set<UUID>
    ) {
        self.schemaVersion = schemaVersion
        self.resetGeneration = resetGeneration
        self.completedLessonIDs = completedLessonIDs
        self.attempts = attempts
        self.appliedEventIDs = appliedEventIDs
    }

    static let empty = Self(
        resetGeneration: 0,
        completedLessonIDs: [],
        attempts: [],
        appliedEventIDs: []
    )
}

struct LearningSyncMergeResult: Equatable, Sendable {
    let snapshot: LearningSyncSnapshot
    let appliedEventIDs: Set<UUID>
    let ignoredEventIDs: Set<UUID>
}

enum LearningSyncDomainError: LocalizedError, Equatable {
    case unsupportedSnapshotSchema(Int)
    case unsupportedEventSchema(Int)
    case invalidResetGeneration(Int)
    case missingDeviceID
    case missingLessonID
    case missingAttempt
    case invalidAttempt(String)
    case generationAdvanceRequiresReset(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSnapshotSchema(version):
            "Unsupported learning sync snapshot schema: \(version)."
        case let .unsupportedEventSchema(version):
            "Unsupported learning sync event schema: \(version)."
        case let .invalidResetGeneration(generation):
            "Invalid learning reset generation: \(generation)."
        case .missingDeviceID:
            "Learning sync event has no originating device identifier."
        case .missingLessonID:
            "Lesson completion sync event has no lesson identifier."
        case .missingAttempt:
            "Learning attempt sync event has no attempt payload."
        case let .invalidAttempt(field):
            "Learning attempt sync event has an invalid \(field)."
        case let .generationAdvanceRequiresReset(generation):
            "Learning sync generation \(generation) requires a reset event."
        }
    }
}

struct MergeLearningSyncUseCase {
    func execute(
        local: LearningSyncSnapshot,
        incoming events: [LearningSyncEvent]
    ) throws -> LearningSyncMergeResult {
        try validate(local)

        var generation = local.resetGeneration
        var completedLessonIDs = local.completedLessonIDs
        var attemptsByID: [UUID: LearningSyncAttempt] = [:]
        for attempt in local.attempts {
            attemptsByID[attempt.id] = attempt
        }
        var knownEventIDs = local.appliedEventIDs
        var appliedEventIDs: Set<UUID> = []
        var ignoredEventIDs: Set<UUID> = []

        for event in events.sorted(by: eventPrecedes) {
            try validate(event)

            guard knownEventIDs.contains(event.id) == false else {
                ignoredEventIDs.insert(event.id)
                continue
            }
            guard event.resetGeneration >= generation else {
                ignoredEventIDs.insert(event.id)
                continue
            }
            if event.resetGeneration > generation {
                guard event.kind == .progressReset else {
                    throw LearningSyncDomainError.generationAdvanceRequiresReset(
                        event.resetGeneration
                    )
                }
                generation = event.resetGeneration
                completedLessonIDs.removeAll()
                attemptsByID.removeAll()
                knownEventIDs.removeAll()
            }

            switch event.kind {
            case .progressReset:
                completedLessonIDs.removeAll()
                attemptsByID.removeAll()
            case .lessonCompleted:
                guard let lessonID = event.lessonID?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ), lessonID.isEmpty == false else {
                    throw LearningSyncDomainError.missingLessonID
                }
                completedLessonIDs.insert(lessonID)
            case .attemptRecorded:
                guard let attempt = event.attempt else {
                    throw LearningSyncDomainError.missingAttempt
                }
                try validate(attempt)
                attemptsByID[attempt.id] = attempt
            }

            knownEventIDs.insert(event.id)
            appliedEventIDs.insert(event.id)
        }

        let snapshot = LearningSyncSnapshot(
            resetGeneration: generation,
            completedLessonIDs: completedLessonIDs,
            attempts: attemptsByID.values.sorted(by: attemptPrecedes),
            appliedEventIDs: knownEventIDs
        )
        return LearningSyncMergeResult(
            snapshot: snapshot,
            appliedEventIDs: appliedEventIDs,
            ignoredEventIDs: ignoredEventIDs
        )
    }

    private func validate(_ snapshot: LearningSyncSnapshot) throws {
        guard snapshot.schemaVersion == LearningSyncSnapshot.currentSchemaVersion else {
            throw LearningSyncDomainError.unsupportedSnapshotSchema(
                snapshot.schemaVersion
            )
        }
        guard snapshot.resetGeneration >= 0 else {
            throw LearningSyncDomainError.invalidResetGeneration(
                snapshot.resetGeneration
            )
        }
        for attempt in snapshot.attempts {
            try validate(attempt)
        }
    }

    private func validate(_ event: LearningSyncEvent) throws {
        guard event.schemaVersion == LearningSyncEvent.currentSchemaVersion else {
            throw LearningSyncDomainError.unsupportedEventSchema(event.schemaVersion)
        }
        guard event.resetGeneration >= 0 else {
            throw LearningSyncDomainError.invalidResetGeneration(
                event.resetGeneration
            )
        }
        guard event.deviceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                == false else {
            throw LearningSyncDomainError.missingDeviceID
        }
    }

    private func validate(_ attempt: LearningSyncAttempt) throws {
        for (name, value) in [
            ("lesson identifier", attempt.lessonID),
            ("skill identifier", attempt.skillID),
            ("activity identifier", attempt.activityID)
        ] where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw LearningSyncDomainError.invalidAttempt(name)
        }
    }

    private func eventPrecedes(
        _ lhs: LearningSyncEvent,
        _ rhs: LearningSyncEvent
    ) -> Bool {
        if lhs.resetGeneration != rhs.resetGeneration {
            return lhs.resetGeneration < rhs.resetGeneration
        }
        if lhs.kind != rhs.kind,
           lhs.kind == .progressReset || rhs.kind == .progressReset {
            return lhs.kind == .progressReset
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func attemptPrecedes(
        _ lhs: LearningSyncAttempt,
        _ rhs: LearningSyncAttempt
    ) -> Bool {
        if lhs.recordedAt != rhs.recordedAt {
            return lhs.recordedAt < rhs.recordedAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}

@MainActor
protocol LearningSyncSnapshotRepository {
    func loadSnapshot() throws -> LearningSyncSnapshot
    func saveSnapshot(_ snapshot: LearningSyncSnapshot) throws
}

@MainActor
protocol LearningSyncEventQueueRepository {
    func loadPendingEvents() throws -> [LearningSyncEvent]
    func enqueue(_ event: LearningSyncEvent) throws
    func removePendingEvents(ids: Set<UUID>) throws
}

@MainActor
protocol LearningSyncRepository:
    LearningSyncSnapshotRepository,
    LearningSyncEventQueueRepository {}

@MainActor
protocol LearningSyncResetGenerationAdopting {
    func adoptResetGeneration(_ generation: Int) throws
}

@MainActor
protocol LearningSyncResetGenerationAdvancing {
    func advanceResetGeneration() throws
}

@MainActor
protocol LearningSyncEventValidating {
    func validate(_ event: LearningSyncEvent) throws
}

@MainActor
struct MergeLearningSyncEventsUseCase {
    private let repository: any LearningSyncSnapshotRepository
    private let validator: any LearningSyncEventValidating
    private let merge: MergeLearningSyncUseCase

    init(
        repository: any LearningSyncSnapshotRepository,
        validator: any LearningSyncEventValidating,
        merge: MergeLearningSyncUseCase = MergeLearningSyncUseCase()
    ) {
        self.repository = repository
        self.validator = validator
        self.merge = merge
    }

    func execute(_ events: [LearningSyncEvent]) throws -> LearningSyncMergeResult {
        for event in events {
            try validator.validate(event)
        }
        let result = try merge.execute(
            local: repository.loadSnapshot(),
            incoming: events
        )
        try repository.saveSnapshot(result.snapshot)
        return result
    }
}

@MainActor
struct LoadPendingLearningSyncEventsUseCase {
    private let repository: any LearningSyncEventQueueRepository

    init(repository: any LearningSyncEventQueueRepository) {
        self.repository = repository
    }

    func execute() throws -> [LearningSyncEvent] {
        try repository.loadPendingEvents()
    }
}

@MainActor
struct LoadLearningSyncSnapshotUseCase {
    private let repository: any LearningSyncSnapshotRepository

    init(repository: any LearningSyncSnapshotRepository) {
        self.repository = repository
    }

    func execute() throws -> LearningSyncSnapshot {
        try repository.loadSnapshot()
    }
}
