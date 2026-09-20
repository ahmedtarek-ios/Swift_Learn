import Foundation
import SwiftData

@MainActor
final class SwiftDataGitTrackRepository: GitTrackProgressRepository,
    GitTrackAttemptRepository,
    GitTrackResetRepository {
    private let modelContext: ModelContext
    private let idGenerator: () -> UUID

    init(modelContext: ModelContext, idGenerator: @escaping () -> UUID = UUID.init) {
        self.modelContext = modelContext
        self.idGenerator = idGenerator
    }

    func loadCompletedLessonIDs() throws -> Set<String> {
        Set(try progressRecords().map(\.lessonID))
    }

    func isCompleted(lessonID: String) throws -> Bool {
        try progressRecords().contains { $0.lessonID == lessonID }
    }

    func markCompleted(lessonID: String) throws {
        guard try isCompleted(lessonID: lessonID) == false else { return }
        modelContext.insert(
            GitLessonProgressRecord(lessonID: lessonID, completedAt: .now)
        )
        try modelContext.save()
    }

    func recordAttempt(
        lessonID: String,
        choiceID: String,
        isCorrect: Bool,
        recordedAt: Date
    ) throws {
        modelContext.insert(
            GitAttemptRecord(
                id: idGenerator(),
                lessonID: lessonID,
                choiceID: choiceID,
                isCorrect: isCorrect,
                recordedAt: recordedAt
            )
        )
        try modelContext.save()
    }

    func attemptCount() throws -> Int {
        try modelContext.fetch(FetchDescriptor<GitAttemptRecord>()).count
    }

    /// Deletes Git progress and Git attempts only. Swift progress, attempts,
    /// project submissions, boss completions, and the profile are untouched.
    func resetGitProgress() throws {
        for record in try progressRecords() {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(FetchDescriptor<GitAttemptRecord>()) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }

    private func progressRecords() throws -> [GitLessonProgressRecord] {
        try modelContext.fetch(FetchDescriptor<GitLessonProgressRecord>())
    }
}

@MainActor
final class InMemoryGitTrackRepository: GitTrackProgressRepository,
    GitTrackAttemptRepository,
    GitTrackResetRepository {
    private var completedLessonIDs: Set<String>
    private(set) var attempts: [(lessonID: String, choiceID: String, isCorrect: Bool)] = []

    init(completedLessonIDs: Set<String> = []) {
        self.completedLessonIDs = completedLessonIDs
    }

    func loadCompletedLessonIDs() throws -> Set<String> { completedLessonIDs }

    func isCompleted(lessonID: String) throws -> Bool {
        completedLessonIDs.contains(lessonID)
    }

    func markCompleted(lessonID: String) throws {
        completedLessonIDs.insert(lessonID)
    }

    func recordAttempt(
        lessonID: String,
        choiceID: String,
        isCorrect: Bool,
        recordedAt: Date
    ) throws {
        attempts.append((lessonID, choiceID, isCorrect))
    }

    func attemptCount() throws -> Int { attempts.count }

    func resetGitProgress() throws {
        completedLessonIDs.removeAll()
        attempts.removeAll()
    }
}
