//
//  LearningProjectSubmissionMapper.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation

enum LearningProjectSubmissionMapper {
    static func record(
        from submission: LearningProjectSubmission
    ) throws -> LearningProjectSubmissionRecord {
        LearningProjectSubmissionRecord(
            id: submission.id,
            projectID: submission.projectID,
            validationResultsData: try JSONEncoder().encode(submission.results),
            submittedAt: submission.submittedAt
        )
    }

    static func domainModel(
        from record: LearningProjectSubmissionRecord
    ) throws -> LearningProjectSubmission {
        guard let results = try? JSONDecoder().decode(
            [LearningProjectValidationResult].self,
            from: record.validationResultsData
        ) else {
            throw LearningProjectDataError.invalidStoredValidationResults
        }
        return LearningProjectSubmission(
            id: record.id,
            projectID: record.projectID,
            results: results,
            submittedAt: record.submittedAt
        )
    }
}
