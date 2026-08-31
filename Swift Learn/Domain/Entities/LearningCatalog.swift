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
    let activity: LearningActivity
    let correctFeedback: String
    let incorrectFeedback: String
    let sourceTitle: String
    let sourceReferences: [String]

    init(
        id: String,
        title: String,
        objective: String,
        instruction: String,
        activity: LearningActivity,
        correctFeedback: String,
        incorrectFeedback: String,
        sourceTitle: String,
        sourceReferences: [String]
    ) {
        self.id = id
        self.title = title
        self.objective = objective
        self.instruction = instruction
        self.activity = activity
        self.correctFeedback = correctFeedback
        self.incorrectFeedback = incorrectFeedback
        self.sourceTitle = sourceTitle
        self.sourceReferences = sourceReferences
    }

    init(
        id: String,
        title: String,
        objective: String,
        instruction: String,
        codePrefix: String,
        codeSuffix: String,
        choices: [LearningChoice],
        correctChoiceID: String,
        correctFeedback: String,
        incorrectFeedback: String,
        sourceTitle: String,
        sourceReferences: [String]
    ) {
        self.init(
            id: id,
            title: title,
            objective: objective,
            instruction: instruction,
            activity: .missingCode(
                MissingCodeActivity(
                    schemaVersion: 1,
                    prompt: "Choose the missing Swift code",
                    codePrefix: codePrefix,
                    codeSuffix: codeSuffix,
                    choices: choices,
                    correctChoiceID: correctChoiceID
                )
            ),
            correctFeedback: correctFeedback,
            incorrectFeedback: incorrectFeedback,
            sourceTitle: sourceTitle,
            sourceReferences: sourceReferences
        )
    }

    var activityID: LearningActivityID {
        LearningActivityID(rawValue: id)
    }

    var choices: [LearningChoice] {
        activity.choices
    }

    var correctChoiceID: String {
        activity.correctChoiceID
    }

    func choice(id: String) -> LearningChoice? {
        choices.first { $0.id == id }
    }

    func code(selectedChoiceID: String?) -> String {
        activity.code(selectedChoiceID: selectedChoiceID)
    }
}

enum LearningActivityKind: String, Equatable, Sendable {
    case missingCode
    case outputPrediction
}

enum LearningActivity: Equatable, Sendable {
    case missingCode(MissingCodeActivity)
    case outputPrediction(OutputPredictionActivity)

    var kind: LearningActivityKind {
        switch self {
        case .missingCode:
            .missingCode
        case .outputPrediction:
            .outputPrediction
        }
    }

    var schemaVersion: Int {
        switch self {
        case let .missingCode(activity):
            activity.schemaVersion
        case let .outputPrediction(activity):
            activity.schemaVersion
        }
    }

    var prompt: String {
        switch self {
        case let .missingCode(activity):
            activity.prompt
        case let .outputPrediction(activity):
            activity.prompt
        }
    }

    var choices: [LearningChoice] {
        switch self {
        case let .missingCode(activity):
            activity.choices
        case let .outputPrediction(activity):
            activity.choices
        }
    }

    var correctChoiceID: String {
        switch self {
        case let .missingCode(activity):
            activity.correctChoiceID
        case let .outputPrediction(activity):
            activity.correctChoiceID
        }
    }

    func code(selectedChoiceID: String?) -> String {
        switch self {
        case let .missingCode(activity):
            activity.code(selectedChoiceID: selectedChoiceID)
        case let .outputPrediction(activity):
            activity.code
        }
    }
}

struct MissingCodeActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let codePrefix: String
    let codeSuffix: String
    let choices: [LearningChoice]
    let correctChoiceID: String

    func code(selectedChoiceID: String?) -> String {
        let token = selectedChoiceID.flatMap { selectedID in
            choices.first { $0.id == selectedID }
        }?.code ?? "___"
        return codePrefix + token + codeSuffix
    }
}

struct OutputPredictionActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let code: String
    let choices: [LearningChoice]
    let correctChoiceID: String
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
