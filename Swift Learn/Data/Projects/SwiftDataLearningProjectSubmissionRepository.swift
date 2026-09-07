//
//  SwiftDataLearningProjectSubmissionRepository.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataLearningProjectSubmissionRepository:
    LearningProjectSubmissionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func record(
        _ submission: LearningProjectSubmission,
        attempts: [LearningAttempt]
    ) throws {
        do {
            modelContext.insert(try LearningProjectSubmissionMapper.record(from: submission))
            for attempt in attempts {
                modelContext.insert(LearningAttemptMapper.record(from: attempt))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func loadLatestSubmission(
        projectID: String
    ) throws -> LearningProjectSubmission? {
        try loadSubmissions(projectID: projectID).first
    }

    func loadSubmissions(
        projectID: String
    ) throws -> [LearningProjectSubmission] {
        let descriptor = FetchDescriptor<LearningProjectSubmissionRecord>(
            predicate: #Predicate { $0.projectID == projectID },
            sortBy: [SortDescriptor(\.submittedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(
            LearningProjectSubmissionMapper.domainModel(from:)
        )
    }
}
