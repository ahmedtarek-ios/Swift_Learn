//
//  LearningCatalog.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation

struct LearningCatalog: Equatable, Sendable {
    let sourceID: String
    let editionTitle: String
    let levels: [LearningLevel]

    var lessons: [LearningLesson] {
        levels.flatMap(\.lessons)
    }

    func lesson(id: String) -> LearningLesson? {
        lessons.first { $0.id == id }
    }
}

struct LearningLevel: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let lessons: [LearningLesson]
}

struct LearningLesson: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let objective: String
    let instruction: String
    let codePrefix: String
    let codeSuffix: String
    let choices: [LearningChoice]
    let correctChoiceID: String
    let correctFeedback: String
    let incorrectFeedback: String
    let sourceTitle: String
    let sourceReferences: [String]

    var activityID: LearningActivityID {
        LearningActivityID(rawValue: id)
    }

    func choice(id: String) -> LearningChoice? {
        choices.first { $0.id == id }
    }

    func code(selectedChoiceID: String?) -> String {
        let token = selectedChoiceID.flatMap(choice(id:))?.code ?? "___"
        return codePrefix + token + codeSuffix
    }
}

struct LearningChoice: Identifiable, Equatable, Sendable {
    let id: String
    let code: String
}

struct LearningJourney: Equatable, Sendable {
    let catalog: LearningCatalog
    let completedLessonIDs: Set<String>

    var completedLessonCount: Int {
        catalog.lessons.filter { completedLessonIDs.contains($0.id) }.count
    }

    var totalLessonCount: Int {
        catalog.lessons.count
    }

    var progress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return Double(completedLessonCount) / Double(totalLessonCount)
    }

    func isCompleted(lessonID: String) -> Bool {
        completedLessonIDs.contains(lessonID)
    }

    func isUnlocked(lessonID: String) -> Bool {
        guard let lessonIndex = catalog.lessons.firstIndex(where: { $0.id == lessonID }) else {
            return false
        }
        guard lessonIndex > 0 else {
            return true
        }

        return completedLessonIDs.contains(catalog.lessons[lessonIndex - 1].id)
    }

    func nextLesson(after lessonID: String) -> LearningLesson? {
        guard let lessonIndex = catalog.lessons.firstIndex(where: { $0.id == lessonID }) else {
            return nil
        }

        let nextIndex = catalog.lessons.index(after: lessonIndex)
        guard catalog.lessons.indices.contains(nextIndex) else {
            return nil
        }

        return catalog.lessons[nextIndex]
    }
}

struct LessonAttemptResult: Equatable, Sendable {
    let isCorrect: Bool
    let feedback: String
}

enum LearningDomainError: LocalizedError, Equatable {
    case lessonNotFound
    case lessonLocked
    case choiceNotFound

    var errorDescription: String? {
        switch self {
        case .lessonNotFound:
            "This lesson is unavailable."
        case .lessonLocked:
            "Complete the previous lesson first."
        case .choiceNotFound:
            "Choose a valid code answer."
        }
    }
}
