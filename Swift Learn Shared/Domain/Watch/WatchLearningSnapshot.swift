import Foundation

nonisolated struct WatchNextLessonSnapshot: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let objective: String
}

/// Review content carried in the snapshot so the Watch can run Quick Review
/// without a second copy of the curriculum.
nonisolated struct WatchReviewChoiceSnapshot: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let text: String
}

nonisolated struct WatchReviewItemSnapshot: Codable, Equatable, Identifiable, Sendable {
    var id: String { skillID }

    let skillID: String
    let lessonID: String
    let activityID: String
    let title: String
    let prompt: String
    let choices: [WatchReviewChoiceSnapshot]
    let correctChoiceID: String
    let correctFeedback: String
    let incorrectFeedback: String
}

/// Level and mastery summary shown by the Watch Progress screen.
nonisolated struct WatchProgressDetailSnapshot: Codable, Equatable, Sendable {
    let levelTitle: String
    let levelCompletedLessonCount: Int
    let levelTotalLessonCount: Int
    let trackedSkillCount: Int
    let proficientSkillCount: Int
    let masteredSkillCount: Int

    var levelProgress: Double {
        guard levelTotalLessonCount > 0 else { return 0 }
        return min(
            max(Double(levelCompletedLessonCount) / Double(levelTotalLessonCount), 0),
            1
        )
    }
}

nonisolated struct WatchLearningSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 4

    let schemaVersion: Int
    let learnerName: String
    let completedLessonCount: Int
    let totalLessonCount: Int
    let dueReviewCount: Int
    let reviewItems: [WatchReviewItemSnapshot]
    let progressDetail: WatchProgressDetailSnapshot?
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
        reviewItems: [WatchReviewItemSnapshot] = [],
        progressDetail: WatchProgressDetailSnapshot? = nil,
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
        self.reviewItems = reviewItems
        self.progressDetail = progressDetail
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
        case reviewItems
        case progressDetail
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
        reviewItems = try container.decodeIfPresent(
            [WatchReviewItemSnapshot].self,
            forKey: .reviewItems
        ) ?? []
        progressDetail = try container.decodeIfPresent(
            WatchProgressDetailSnapshot.self,
            forKey: .progressDetail
        )
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
