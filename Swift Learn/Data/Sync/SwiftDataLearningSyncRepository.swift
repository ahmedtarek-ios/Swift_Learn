import Foundation
import SwiftData

@MainActor
final class SwiftDataLearningSyncRepository:
    LearningSyncSnapshotRepository,
    LearningSyncResetGenerationAdvancing {
    private static let stateKey = "primary"

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSnapshot() throws -> LearningSyncSnapshot {
        let state = try storedState()
        let resetGeneration = state?.resetGeneration ?? 0
        let completedLessonIDs = Set(
            try modelContext.fetch(FetchDescriptor<LessonProgressRecord>())
                .map(\.lessonID)
        )
        let attempts = try modelContext.fetch(FetchDescriptor<LearningAttemptRecord>())
            .map(syncAttempt(from:))
        let appliedEventIDs = Set(
            try modelContext.fetch(FetchDescriptor<LearningSyncEventReceiptRecord>())
                .filter { $0.resetGeneration == resetGeneration }
                .map(\.eventID)
        )

        return LearningSyncSnapshot(
            resetGeneration: resetGeneration,
            completedLessonIDs: completedLessonIDs,
            attempts: attempts.sorted(by: attemptPrecedes),
            appliedEventIDs: appliedEventIDs
        )
    }

    func saveSnapshot(_ snapshot: LearningSyncSnapshot) throws {
        guard snapshot.schemaVersion == LearningSyncSnapshot.currentSchemaVersion else {
            throw LearningSyncDomainError.unsupportedSnapshotSchema(
                snapshot.schemaVersion
            )
        }

        let state = try stateForWriting()
        guard snapshot.resetGeneration >= state.resetGeneration else {
            throw LearningSyncDataError.staleResetGeneration(
                snapshot.resetGeneration
            )
        }

        if snapshot.resetGeneration > state.resetGeneration {
            try deleteLearningState()
            for receipt in try modelContext.fetch(
                FetchDescriptor<LearningSyncEventReceiptRecord>()
            ) {
                modelContext.delete(receipt)
            }
            state.resetGeneration = snapshot.resetGeneration
        }

        let completedRecords = try modelContext.fetch(
            FetchDescriptor<LessonProgressRecord>()
        )
        let existingLessonIDs = Set(completedRecords.map(\.lessonID))
        for lessonID in snapshot.completedLessonIDs.subtracting(existingLessonIDs) {
            modelContext.insert(
                LessonProgressRecord(lessonID: lessonID, completedAt: .now)
            )
        }

        let existingAttempts = try modelContext.fetch(
            FetchDescriptor<LearningAttemptRecord>()
        )
        let existingAttemptIDs = Set(existingAttempts.map(\.id))
        for attempt in snapshot.attempts where existingAttemptIDs.contains(attempt.id) == false {
            modelContext.insert(record(from: attempt))
        }

        let existingReceipts = try modelContext.fetch(
            FetchDescriptor<LearningSyncEventReceiptRecord>()
        )
        let existingReceiptIDs = Set(existingReceipts.map(\.eventID))
        for eventID in snapshot.appliedEventIDs
            where existingReceiptIDs.contains(eventID) == false {
            modelContext.insert(
                LearningSyncEventReceiptRecord(
                    eventID: eventID,
                    resetGeneration: snapshot.resetGeneration
                )
            )
        }

        try modelContext.save()
    }

    func advanceResetGeneration() throws {
        let state = try stateForWriting()
        state.resetGeneration += 1
        for receipt in try modelContext.fetch(
            FetchDescriptor<LearningSyncEventReceiptRecord>()
        ) {
            modelContext.delete(receipt)
        }
        try modelContext.save()
    }

    private func storedState() throws -> LearningSyncStateRecord? {
        try modelContext.fetch(
            FetchDescriptor<LearningSyncStateRecord>()
        ).first(where: { $0.key == Self.stateKey })
    }

    private func stateForWriting() throws -> LearningSyncStateRecord {
        if let state = try storedState() { return state }
        let state = LearningSyncStateRecord(resetGeneration: 0)
        modelContext.insert(state)
        return state
    }

    private func deleteLearningState() throws {
        for record in try modelContext.fetch(FetchDescriptor<LessonProgressRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<LearningAttemptRecord>()) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(
            FetchDescriptor<LearningProjectSubmissionRecord>()
        ) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(
            FetchDescriptor<BossChallengeCompletionRecord>()
        ) {
            modelContext.delete(record)
        }
    }

    private func syncAttempt(from record: LearningAttemptRecord) throws -> LearningSyncAttempt {
        guard let outcome = LearningSyncAttemptOutcome(
            rawValue: record.outcomeRawValue
        ) else {
            throw LearningSyncDataError.invalidOutcome(record.outcomeRawValue)
        }
        let errorCategory: LearningSyncErrorCategory?
        if let rawValue = record.errorCategoryRawValue {
            guard let category = LearningSyncErrorCategory(rawValue: rawValue) else {
                throw LearningSyncDataError.invalidErrorCategory(rawValue)
            }
            errorCategory = category
        } else {
            errorCategory = nil
        }

        return LearningSyncAttempt(
            id: record.id,
            lessonID: record.lessonID,
            skillID: record.skillID,
            activityID: record.activityID,
            outcome: outcome,
            errorCategory: errorCategory,
            recordedAt: record.recordedAt
        )
    }

    private func record(from attempt: LearningSyncAttempt) -> LearningAttemptRecord {
        LearningAttemptRecord(
            id: attempt.id,
            lessonID: attempt.lessonID,
            skillID: attempt.skillID,
            activityID: attempt.activityID,
            outcomeRawValue: attempt.outcome.rawValue,
            errorCategoryRawValue: attempt.errorCategory?.rawValue,
            recordedAt: attempt.recordedAt
        )
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

enum LearningSyncDataError: LocalizedError, Equatable {
    case staleResetGeneration(Int)
    case invalidOutcome(String)
    case invalidErrorCategory(String)

    var errorDescription: String? {
        switch self {
        case let .staleResetGeneration(generation):
            "Cannot save stale learning reset generation: \(generation)."
        case let .invalidOutcome(value):
            "Stored sync attempt has an invalid outcome: \(value)."
        case let .invalidErrorCategory(value):
            "Stored sync attempt has an invalid error category: \(value)."
        }
    }
}
