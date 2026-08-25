//
//  SwiftDataLearningAttemptRepository.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import SwiftData

@MainActor
final class SwiftDataLearningAttemptRepository: LearningAttemptRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func record(_ attempt: LearningAttempt) throws {
        modelContext.insert(LearningAttemptMapper.record(from: attempt))
        try modelContext.save()
    }

    func loadAttempts(skillID: SkillID) throws -> [LearningAttempt] {
        try modelContext.fetch(FetchDescriptor<LearningAttemptRecord>())
            .filter { $0.skillID == skillID.rawValue }
            .map(LearningAttemptMapper.domainModel(from:))
    }

    func loadAllAttempts() throws -> [LearningAttempt] {
        try modelContext.fetch(FetchDescriptor<LearningAttemptRecord>())
            .map(LearningAttemptMapper.domainModel(from:))
    }
}
