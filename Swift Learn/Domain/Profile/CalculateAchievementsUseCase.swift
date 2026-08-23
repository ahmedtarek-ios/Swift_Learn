//
//  CalculateAchievementsUseCase.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
struct CalculateAchievementsUseCase {
    func execute(journey: LearningJourney) -> [AchievementProgress] {
        let completedLessonCount = journey.completedLessonCount
        let completedLevelCount = journey.catalog.levels.filter { level in
            !level.lessons.isEmpty
                && level.lessons.allSatisfy {
                    journey.completedLessonIDs.contains($0.id)
                }
        }.count

        var achievements = [
            AchievementProgress(
                definition: AchievementDefinition(
                    id: "achievement.first-lesson",
                    title: "First Lesson",
                    summary: "Complete your first Swift lesson.",
                    kind: .firstLesson
                ),
                completedRequirementCount: completedLessonCount,
                totalRequirementCount: 1
            ),
            AchievementProgress(
                definition: AchievementDefinition(
                    id: "achievement.first-level",
                    title: "First Level",
                    summary: "Complete every lesson in one level.",
                    kind: .firstLevel
                ),
                completedRequirementCount: completedLevelCount,
                totalRequirementCount: 1
            )
        ]

        for milestone in [10, 50, 100] {
            achievements.append(
                AchievementProgress(
                    definition: AchievementDefinition(
                        id: "achievement.lessons.\(milestone)",
                        title: "\(milestone) Lessons",
                        summary: "Complete \(milestone) Swift lessons.",
                        kind: .lessonMilestone(milestone)
                    ),
                    completedRequirementCount: completedLessonCount,
                    totalRequirementCount: milestone
                )
            )
        }

        achievements.append(
            contentsOf: journey.catalog.levels.map { level in
                let completedLessons = level.lessons.filter {
                    journey.completedLessonIDs.contains($0.id)
                }.count

                return AchievementProgress(
                    definition: AchievementDefinition(
                        id: "achievement.level.\(level.id)",
                        title: level.title,
                        summary: "Complete every lesson in \(level.title).",
                        kind: .level(level.id)
                    ),
                    completedRequirementCount: completedLessons,
                    totalRequirementCount: level.lessons.count
                )
            }
        )

        achievements.append(
            AchievementProgress(
                definition: AchievementDefinition(
                    id: "achievement.source-complete",
                    title: "Source Complete",
                    summary: "Complete every lesson in the current Swift source.",
                    kind: .sourceCompletion
                ),
                completedRequirementCount: completedLessonCount,
                totalRequirementCount: journey.totalLessonCount
            )
        )

        return achievements
    }
}
