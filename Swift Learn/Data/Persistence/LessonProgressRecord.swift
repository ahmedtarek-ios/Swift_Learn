//
//  LessonProgressRecord.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import Foundation
import SwiftData

@Model
final class LessonProgressRecord {
    @Attribute(.unique) var lessonID: String
    /// Optional so the store migrates lightly. A record without a track is a
    /// pre-Git Swift record.
    var trackID: String?

    var learningTrackID: LearningTrackID {
        trackID.flatMap(LearningTrackID.init(rawValue:)) ?? .swift
    }
    var completedAt: Date

    init(
        lessonID: String,
        trackID: String = LearningTrackID.swift.rawValue,
        completedAt: Date
    ) {
        self.lessonID = lessonID
        self.trackID = trackID
        self.completedAt = completedAt
    }
}
