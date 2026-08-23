//
//  LearningProgressEvent.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

enum LearningProgressEvent: Identifiable, Equatable, Sendable {
    case lessonCompleted(String)
    case lessonUnlocked(String)
    case levelCompleted(String)
    case achievementEarned(AchievementProgress)

    var id: String {
        switch self {
        case let .lessonCompleted(lessonID):
            "lesson-completed-\(lessonID)"
        case let .lessonUnlocked(lessonID):
            "lesson-unlocked-\(lessonID)"
        case let .levelCompleted(levelID):
            "level-completed-\(levelID)"
        case let .achievementEarned(achievement):
            "achievement-earned-\(achievement.id)"
        }
    }
}
