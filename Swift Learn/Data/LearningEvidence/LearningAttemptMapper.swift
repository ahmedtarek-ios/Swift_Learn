//
//  LearningAttemptMapper.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

enum LearningAttemptMapper {
    static func record(from attempt: LearningAttempt) -> LearningAttemptRecord {
        LearningAttemptRecord(
            id: attempt.id,
            lessonID: attempt.evidence.lessonID,
            skillID: attempt.evidence.skillID.rawValue,
            activityID: attempt.evidence.activityID.rawValue,
            outcomeRawValue: attempt.evidence.outcome.rawValue,
            errorCategoryRawValue: attempt.evidence.errorCategory?.rawValue,
            recordedAt: attempt.recordedAt
        )
    }

    static func domainModel(from record: LearningAttemptRecord) throws -> LearningAttempt {
        guard let outcome = AttemptOutcome(rawValue: record.outcomeRawValue) else {
            throw LearningEvidenceDataError.invalidOutcome(record.outcomeRawValue)
        }

        let errorCategory: LearningErrorCategory?
        if let rawValue = record.errorCategoryRawValue {
            guard let category = LearningErrorCategory(rawValue: rawValue) else {
                throw LearningEvidenceDataError.invalidErrorCategory(rawValue)
            }
            errorCategory = category
        } else {
            errorCategory = nil
        }

        return LearningAttempt(
            id: record.id,
            evidence: LearningEvidence(
                lessonID: record.lessonID,
                skillID: SkillID(rawValue: record.skillID),
                activityID: LearningActivityID(rawValue: record.activityID),
                outcome: outcome,
                errorCategory: errorCategory
            ),
            recordedAt: record.recordedAt
        )
    }
}

enum LearningEvidenceDataError: LocalizedError, Equatable {
    case invalidOutcome(String)
    case invalidErrorCategory(String)

    var errorDescription: String? {
        switch self {
        case let .invalidOutcome(value):
            "Stored attempt has an invalid outcome: \(value)."
        case let .invalidErrorCategory(value):
            "Stored attempt has an invalid error category: \(value)."
        }
    }
}
