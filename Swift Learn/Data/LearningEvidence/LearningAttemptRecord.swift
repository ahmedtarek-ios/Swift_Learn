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
    /// Optional so the store migrates lightly. A record without a track is a
    /// pre-Git Swift record.
    var trackID: String?

    var learningTrackID: LearningTrackID {
        trackID.flatMap(LearningTrackID.init(rawValue:)) ?? .swift
    }
    var lessonID: String
    var skillID: String
    var activityID: String
    var outcomeRawValue: String
    var errorCategoryRawValue: String?
    var recordedAt: Date

    init(
        id: UUID,
        trackID: String = LearningTrackID.swift.rawValue,
        lessonID: String,
        skillID: String,
        activityID: String,
        outcomeRawValue: String,
        errorCategoryRawValue: String?,
        recordedAt: Date
    ) {
        self.id = id
        self.trackID = trackID
        self.lessonID = lessonID
        self.skillID = skillID
        self.activityID = activityID
        self.outcomeRawValue = outcomeRawValue
        self.errorCategoryRawValue = errorCategoryRawValue
        self.recordedAt = recordedAt
    }
}
