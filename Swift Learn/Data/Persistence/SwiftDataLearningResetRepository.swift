//
//  SwiftDataLearningResetRepository.swift
//  Swift Learn
//
//  Created by Codex on 31/08/2026.
//

import SwiftData

@MainActor
final class SwiftDataLearningResetRepository: LearningResetRepository {
    private let modelContext: ModelContext
    private let syncGeneration: any LearningSyncResetGenerationAdvancing

    init(
        modelContext: ModelContext,
        syncGeneration: any LearningSyncResetGenerationAdvancing
    ) {
        self.modelContext = modelContext
        self.syncGeneration = syncGeneration
    }

    func resetLearningProgress() throws {
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
        try syncGeneration.advanceResetGeneration()
    }
}
