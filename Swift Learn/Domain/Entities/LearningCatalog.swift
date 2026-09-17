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

    var correctChoiceID: String? {
        activity.correctChoiceID
    }

    func choice(id: String) -> LearningChoice? {
        guard activity.kind != .codeOrdering,
              activity.kind != .constrainedEditing,
              activity.kind != .unitTestAuthoring,
              activity.kind != .uiTestAuthoring,
              activity.kind != .architectureClassification,
              activity.kind != .projectValidation else { return nil }
        return choices.first { $0.id == id }
    }

    func code(selectedChoiceID: String?) -> String {
        activity.code(selectedChoiceID: selectedChoiceID)
    }
}

enum LearningActivityKind: String, Equatable, Sendable {
    case missingCode
    case outputPrediction
    case codeOrdering
    case diagnosticSelection
    case codeRepair
    case constrainedEditing
    case unitTestAuthoring
    case uiTestAuthoring
    case architectureClassification
    case projectValidation
}

enum LearningActivityResponse: Equatable, Sendable {
    case choice(String)
    case orderedFragments([String])
    case text(String)
    case classifications([String: ArchitectureLayer])
    case projectSubmission(LearningProjectSubmission)
}

enum LearningActivity: Equatable, Sendable {
    case missingCode(MissingCodeActivity)
    case outputPrediction(OutputPredictionActivity)
    case codeOrdering(CodeOrderingActivity)
    case diagnosticSelection(DiagnosticSelectionActivity)
    case codeRepair(CodeRepairActivity)
    case constrainedEditing(ConstrainedEditingActivity)
    case unitTestAuthoring(UnitTestAuthoringActivity)
    case uiTestAuthoring(UITestAuthoringActivity)
    case architectureClassification(ArchitectureClassificationActivity)
    case projectValidation(ProjectValidationActivity)

    var kind: LearningActivityKind {
        switch self {
        case .missingCode:
            .missingCode
        case .outputPrediction:
            .outputPrediction
        case .codeOrdering:
            .codeOrdering
        case .diagnosticSelection:
            .diagnosticSelection
        case .codeRepair:
            .codeRepair
        case .constrainedEditing:
            .constrainedEditing
        case .unitTestAuthoring:
            .unitTestAuthoring
        case .uiTestAuthoring:
            .uiTestAuthoring
        case .architectureClassification:
            .architectureClassification
        case .projectValidation:
            .projectValidation
        }
    }

    var schemaVersion: Int {
        switch self {
        case let .missingCode(activity):
            activity.schemaVersion
        case let .outputPrediction(activity):
            activity.schemaVersion
        case let .codeOrdering(activity):
            activity.schemaVersion
        case let .diagnosticSelection(activity):
            activity.schemaVersion
        case let .codeRepair(activity):
            activity.schemaVersion
        case let .constrainedEditing(activity):
            activity.schemaVersion
        case let .unitTestAuthoring(activity):
            activity.schemaVersion
        case let .uiTestAuthoring(activity):
            activity.schemaVersion
        case let .architectureClassification(activity):
            activity.schemaVersion
        case let .projectValidation(activity):
            activity.schemaVersion
        }
    }

    var prompt: String {
        switch self {
        case let .missingCode(activity):
            activity.prompt
        case let .outputPrediction(activity):
            activity.prompt
        case let .codeOrdering(activity):
            activity.prompt
        case let .diagnosticSelection(activity):
            activity.prompt
        case let .codeRepair(activity):
            activity.prompt
        case let .constrainedEditing(activity):
            activity.prompt
        case let .unitTestAuthoring(activity):
            activity.prompt
        case let .uiTestAuthoring(activity):
            activity.prompt
        case let .architectureClassification(activity):
            activity.prompt
        case let .projectValidation(activity):
            activity.prompt
        }
    }

    var choices: [LearningChoice] {
        switch self {
        case let .missingCode(activity):
            activity.choices
        case let .outputPrediction(activity):
            activity.choices
        case let .codeOrdering(activity):
            activity.fragments
        case let .diagnosticSelection(activity):
            activity.choices
        case let .codeRepair(activity):
            activity.choices
        case let .constrainedEditing(activity):
            activity.tokens
        case let .unitTestAuthoring(activity):
            activity.composition.tokens
        case let .uiTestAuthoring(activity):
            activity.composition.tokens
        case .architectureClassification:
            ArchitectureLayer.allCases.map {
                LearningChoice(id: $0.rawValue, code: $0.rawValue.capitalized)
            }
        case .projectValidation:
            []
        }
    }

    var correctChoiceID: String? {
        switch self {
        case let .missingCode(activity):
            activity.correctChoiceID
        case let .outputPrediction(activity):
            activity.correctChoiceID
        case .codeOrdering:
            nil
        case let .diagnosticSelection(activity):
            activity.correctChoiceID
        case let .codeRepair(activity):
            activity.correctChoiceID
        case .constrainedEditing:
            nil
        case .unitTestAuthoring, .uiTestAuthoring, .architectureClassification,
             .projectValidation:
            nil
        }
    }

    var textComposition: ConstrainedEditingActivity? {
        switch self {
        case let .constrainedEditing(activity):
            activity
        case let .unitTestAuthoring(activity):
            activity.composition
        case let .uiTestAuthoring(activity):
            activity.composition
        default:
            nil
        }
    }

    func accepts(_ response: LearningActivityResponse) -> Bool {
        switch (self, response) {
        case let (.missingCode(activity), .choice(id)):
            activity.choices.contains { $0.id == id }
        case let (.outputPrediction(activity), .choice(id)):
            activity.choices.contains { $0.id == id }
        case let (.codeOrdering(activity), .orderedFragments(ids)):
            ids.count == activity.fragments.count
                && Set(ids).count == ids.count
                && Set(ids) == Set(activity.fragments.map(\.id))
        case let (.diagnosticSelection(activity), .choice(id)):
            activity.choices.contains { $0.id == id }
        case let (.codeRepair(activity), .choice(id)):
            activity.choices.contains { $0.id == id }
        case let (.constrainedEditing(activity), .text(text)):
            !text.isEmpty && text.count <= activity.maxLength
                && text.contains("\n") == false
        case let (.unitTestAuthoring(activity), .text(text)):
            !text.isEmpty && text.count <= activity.composition.maxLength
                && text.contains("\n") == false
        case let (.uiTestAuthoring(activity), .text(text)):
            !text.isEmpty && text.count <= activity.composition.maxLength
                && text.contains("\n") == false
        case let (.architectureClassification(activity), .classifications(answers)):
            answers.count == activity.items.count
                && Set(answers.keys) == Set(activity.items.map(\.id))
        case let (.projectValidation(activity), .projectSubmission(submission)):
            activity.accepts(submission)
        default:
            false
        }
    }

    func isCorrect(_ response: LearningActivityResponse) -> Bool {
        guard accepts(response) else { return false }
        return switch (self, response) {
        case let (.missingCode(activity), .choice(id)):
            id == activity.correctChoiceID
        case let (.outputPrediction(activity), .choice(id)):
            id == activity.correctChoiceID
        case let (.codeOrdering(activity), .orderedFragments(ids)):
            ids == activity.correctOrderIDs
        case let (.diagnosticSelection(activity), .choice(id)):
            id == activity.correctChoiceID
        case let (.codeRepair(activity), .choice(id)):
            id == activity.correctChoiceID
        case let (.constrainedEditing(activity), .text(text)):
            activity.acceptedSolutions.contains(text)
        case let (.unitTestAuthoring(activity), .text(text)):
            activity.composition.acceptedSolutions.contains(text)
        case let (.uiTestAuthoring(activity), .text(text)):
            activity.composition.acceptedSolutions.contains(text)
        case let (.architectureClassification(activity), .classifications(answers)):
            activity.items.allSatisfy { answers[$0.id] == $0.correctLayer }
        case (.projectValidation, let .projectSubmission(submission)):
            submission.isPassed
        default:
            false
        }
    }

    func code(selectedChoiceID: String?) -> String {
        switch self {
        case let .missingCode(activity):
            activity.code(selectedChoiceID: selectedChoiceID)
        case let .outputPrediction(activity):
            activity.code
        case let .codeOrdering(activity):
            activity.fragments.map(\.code).joined(separator: "\n")
        case let .diagnosticSelection(activity):
            activity.code
        case let .codeRepair(activity):
            activity.code(selectedChoiceID: selectedChoiceID)
        case let .constrainedEditing(activity):
            activity.code(enteredText: activity.starterText)
        case let .unitTestAuthoring(activity):
            activity.composition.code(enteredText: activity.composition.starterText)
        case let .uiTestAuthoring(activity):
            activity.composition.code(enteredText: activity.composition.starterText)
        case .architectureClassification:
            ""
        case .projectValidation:
            ""
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

struct CodeOrderingActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let fragments: [LearningChoice]
    let correctOrderIDs: [String]

    func code(selectedFragmentIDs: [String]) -> String {
        selectedFragmentIDs.compactMap { id in
            fragments.first { $0.id == id }?.code
        }.joined(separator: "\n")
    }
}

struct DiagnosticSelectionActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let code: String
    let choices: [LearningChoice]
    let correctChoiceID: String
}

struct CodeRepairActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let codePrefix: String
    let faultyCode: String
    let codeSuffix: String
    let choices: [LearningChoice]
    let correctChoiceID: String

    func code(selectedChoiceID: String?) -> String {
        let replacement = selectedChoiceID.flatMap { id in
            choices.first { $0.id == id }?.code
        } ?? faultyCode
        return codePrefix + replacement + codeSuffix
    }
}

struct ConstrainedEditingActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let codePrefix: String
    let codeSuffix: String
    let starterText: String
    let acceptedSolutions: [String]
    let maxLength: Int
    let tokens: [LearningChoice]
    let canonicalTokenIDs: [String]

    var isWellFormed: Bool {
        maxLength > 0 && maxLength <= 200
            && starterText.count <= maxLength
            && acceptedSolutions.isEmpty == false
            && acceptedSolutions.allSatisfy {
                $0.isEmpty == false && $0.count <= maxLength
                    && $0.contains("\n") == false
            }
            && tokens.count >= 2
            && tokens.allSatisfy { $0.id.isEmpty == false && $0.code.isEmpty == false }
            && Set(tokens.map(\.id)).count == tokens.count
            && canonicalTokenIDs.count == tokens.count
            && Set(canonicalTokenIDs) == Set(tokens.map(\.id))
            && acceptedSolutions.contains(text(selectedTokenIDs: canonicalTokenIDs))
    }

    func code(enteredText: String) -> String {
        codePrefix + enteredText + codeSuffix
    }

    func text(selectedTokenIDs: [String]) -> String {
        selectedTokenIDs.compactMap { id in
            tokens.first { $0.id == id }?.code
        }.joined()
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

    var resumeLesson: LearningLesson? {
        catalog.lessons.first { lesson in
            isUnlocked(lessonID: lesson.id) && !isCompleted(lessonID: lesson.id)
        }
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

    func availability(for lessonID: String) -> LearningLessonAvailability {
        guard let lessonIndex = catalog.lessons.firstIndex(where: { $0.id == lessonID }) else {
            return .unavailable
        }
        if isCompleted(lessonID: lessonID) {
            return .completed
        }
        guard lessonIndex > 0 else {
            return .available
        }

        let prerequisite = catalog.lessons[lessonIndex - 1]
        if completedLessonIDs.contains(prerequisite.id) {
            return .available
        }
        return .locked(
            prerequisiteLessonID: prerequisite.id,
            prerequisiteTitle: prerequisite.title
        )
    }

    func progress(for level: LearningLevel) -> LearningLevelProgress {
        LearningLevelProgress(
            levelID: level.id,
            completedLessonCount: level.lessons.count {
                completedLessonIDs.contains($0.id)
            },
            totalLessonCount: level.lessons.count
        )
    }
}

enum LearningLessonAvailability: Equatable, Sendable {
    case unavailable
    case locked(prerequisiteLessonID: String, prerequisiteTitle: String)
    case available
    case completed

    var canPractice: Bool {
        self == .available || self == .completed
    }
}

struct LearningLevelProgress: Equatable, Sendable {
    let levelID: String
    let completedLessonCount: Int
    let totalLessonCount: Int

    var progress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return Double(completedLessonCount) / Double(totalLessonCount)
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
    case invalidActivityResponse

    var errorDescription: String? {
        switch self {
        case .lessonNotFound:
            "This lesson is unavailable."
        case .lessonLocked:
            "Complete the previous lesson first."
        case .choiceNotFound:
            "Choose a valid code answer."
        case .invalidActivityResponse:
            "Complete the activity with a valid answer."
        }
    }
}
