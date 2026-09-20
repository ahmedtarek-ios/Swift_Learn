import Foundation
import SwiftData

/// Git-track progress. A separate record type keeps the two tracks isolated,
/// and `trackID` records the owning track explicitly rather than by prefix.
@Model
final class GitLessonProgressRecord {
    @Attribute(.unique) var lessonID: String
    var trackID: String
    var completedAt: Date

    init(
        lessonID: String,
        trackID: String = LearningTrackID.git.rawValue,
        completedAt: Date
    ) {
        self.lessonID = lessonID
        self.trackID = trackID
        self.completedAt = completedAt
    }
}

@Model
final class GitAttemptRecord {
    @Attribute(.unique) var id: UUID
    var trackID: String
    var lessonID: String
    var choiceID: String
    var isCorrect: Bool
    var recordedAt: Date

    init(
        id: UUID,
        trackID: String = LearningTrackID.git.rawValue,
        lessonID: String,
        choiceID: String,
        isCorrect: Bool,
        recordedAt: Date
    ) {
        self.id = id
        self.trackID = trackID
        self.lessonID = lessonID
        self.choiceID = choiceID
        self.isCorrect = isCorrect
        self.recordedAt = recordedAt
    }
}
