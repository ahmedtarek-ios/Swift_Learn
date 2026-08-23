//
//  CalculateLearningProgressEventsUseCase.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
struct CalculateLearningProgressEventsUseCase {
    private let calculateAchievements: CalculateAchievementsUseCase

    init(calculateAchievements: CalculateAchievementsUseCase) {
        self.calculateAchievements = calculateAchievements
    }

    func execute(
        before: LearningJourney,
        after: LearningJourney
    ) -> [LearningProgressEvent] {
        let newlyCompletedLessonIDs = after.completedLessonIDs
            .subtracting(before.completedLessonIDs)
        let lessonEvents = after.catalog.lessons.compactMap { lesson in
            newlyCompletedLessonIDs.contains(lesson.id)
                ? LearningProgressEvent.lessonCompleted(lesson.id)
                : nil
        }

        let unlockEvents = after.catalog.lessons.compactMap { lesson in
            !before.isUnlocked(lessonID: lesson.id)
                && after.isUnlocked(lessonID: lesson.id)
                ? LearningProgressEvent.lessonUnlocked(lesson.id)
                : nil
        }

        let levelEvents = after.catalog.levels.compactMap { level in
            !isCompleted(level, in: before)
                && isCompleted(level, in: after)
                ? LearningProgressEvent.levelCompleted(level.id)
                : nil
        }

        let previouslyEarnedIDs = Set(
            calculateAchievements.execute(journey: before)
                .filter(\.isEarned)
                .map(\.id)
        )
        let achievementEvents = calculateAchievements.execute(journey: after)
            .filter { $0.isEarned && !previouslyEarnedIDs.contains($0.id) }
            .map(LearningProgressEvent.achievementEarned)

        return lessonEvents + unlockEvents + levelEvents + achievementEvents
    }

    private func isCompleted(
        _ level: LearningLevel,
        in journey: LearningJourney
    ) -> Bool {
        !level.lessons.isEmpty
            && level.lessons.allSatisfy {
                journey.completedLessonIDs.contains($0.id)
            }
    }
}
