import Foundation

struct WatchNextLessonSnapshot: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let objective: String
}

struct WatchLearningSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let learnerName: String
    let completedLessonCount: Int
    let totalLessonCount: Int
    let dueReviewCount: Int
    let nextLesson: WatchNextLessonSnapshot?
    let generatedAt: Date

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        learnerName: String,
        completedLessonCount: Int,
        totalLessonCount: Int,
        dueReviewCount: Int,
        nextLesson: WatchNextLessonSnapshot?,
        generatedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.learnerName = learnerName
        self.completedLessonCount = completedLessonCount
        self.totalLessonCount = totalLessonCount
        self.dueReviewCount = dueReviewCount
        self.nextLesson = nextLesson
        self.generatedAt = generatedAt
    }

    var progress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return min(
            max(Double(completedLessonCount) / Double(totalLessonCount), 0),
            1
        )
    }
}
