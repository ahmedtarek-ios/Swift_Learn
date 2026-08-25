//
//  LearningAttemptRecord.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation
import SwiftData

@Model
final class LearningAttemptRecord {
    @Attribute(.unique) var id: UUID
    var lessonID: String
    var skillID: String
    var activityID: String
    var outcomeRawValue: String
    var errorCategoryRawValue: String?
    var recordedAt: Date

    init(
        id: UUID,
        lessonID: String,
        skillID: String,
        activityID: String,
        outcomeRawValue: String,
        errorCategoryRawValue: String?,
        recordedAt: Date
    ) {
        self.id = id
        self.lessonID = lessonID
        self.skillID = skillID
        self.activityID = activityID
        self.outcomeRawValue = outcomeRawValue
        self.errorCategoryRawValue = errorCategoryRawValue
        self.recordedAt = recordedAt
    }
}
