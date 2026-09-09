import Foundation

struct LearnerDataReport: Equatable, Sendable {
    let sourceID: String
    let completedLessonCount: Int
    let totalLessonCount: Int
    let completedLevelCount: Int
    let masteredSkillCount: Int
    let reviewDueCount: Int
    let recentActivityCount: Int
    let earnedAchievementCount: Int

    var exportText: String {
        [
            "Swift Learn data export",
            "Source: \(sourceID)",
            "Lessons: \(completedLessonCount)/\(totalLessonCount)",
            "Levels completed: \(completedLevelCount)",
            "Skills mastered: \(masteredSkillCount)",
            "Reviews due: \(reviewDueCount)",
            "Recent activities: \(recentActivityCount)",
            "Achievements earned: \(earnedAchievementCount)"
        ].joined(separator: "\n")
    }
}

struct CreateLearnerDataReportUseCase {
    func execute(
        snapshot: LearnerProfileSnapshot,
        mastery: MasteryOverview?,
        recentActivities: [RecentLearningActivity],
        achievements: [AchievementProgress]
    ) -> LearnerDataReport {
        LearnerDataReport(
            sourceID: snapshot.journey.catalog.sourceID,
            completedLessonCount: snapshot.journey.completedLessonCount,
            totalLessonCount: snapshot.journey.totalLessonCount,
            completedLevelCount: snapshot.completedLevelCount,
            masteredSkillCount: mastery?.masteredCount ?? 0,
            reviewDueCount: mastery?.reviewDueCount ?? 0,
            recentActivityCount: recentActivities.count,
            earnedAchievementCount: achievements.count(where: \.isEarned)
        )
    }
}
