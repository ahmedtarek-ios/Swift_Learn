import Foundation

struct WatchNextLessonSnapshot: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let objective: String
}

struct WatchLearningSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let learnerName: String
    let completedLessonCount: Int
    let totalLessonCount: Int
    let dueReviewCount: Int
    let nextLesson: WatchNextLessonSnapshot?
    let resetGeneration: Int
    let acknowledgedEventIDs: Set<UUID>
    let generatedAt: Date

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        learnerName: String,
        completedLessonCount: Int,
        totalLessonCount: Int,
        dueReviewCount: Int,
        nextLesson: WatchNextLessonSnapshot?,
        resetGeneration: Int = 0,
        acknowledgedEventIDs: Set<UUID> = [],
        generatedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.learnerName = learnerName
        self.completedLessonCount = completedLessonCount
        self.totalLessonCount = totalLessonCount
        self.dueReviewCount = dueReviewCount
        self.nextLesson = nextLesson
        self.resetGeneration = resetGeneration
        self.acknowledgedEventIDs = acknowledgedEventIDs
        self.generatedAt = generatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case learnerName
        case completedLessonCount
        case totalLessonCount
        case dueReviewCount
        case nextLesson
        case resetGeneration
        case acknowledgedEventIDs
        case generatedAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        learnerName = try container.decode(String.self, forKey: .learnerName)
        completedLessonCount = try container.decode(
            Int.self,
            forKey: .completedLessonCount
        )
        totalLessonCount = try container.decode(Int.self, forKey: .totalLessonCount)
        dueReviewCount = try container.decode(Int.self, forKey: .dueReviewCount)
        nextLesson = try container.decodeIfPresent(
            WatchNextLessonSnapshot.self,
            forKey: .nextLesson
        )
        resetGeneration = try container.decodeIfPresent(
            Int.self,
            forKey: .resetGeneration
        ) ?? 0
        acknowledgedEventIDs = try container.decodeIfPresent(
            Set<UUID>.self,
            forKey: .acknowledgedEventIDs
        ) ?? []
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
    }

    var progress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return min(
            max(Double(completedLessonCount) / Double(totalLessonCount), 0),
            1
        )
    }
}
