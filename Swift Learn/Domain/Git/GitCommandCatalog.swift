import Foundation

/// How risky a command is for the learner's repository. Domain owns this
/// classification; the app never executes a command.
enum GitCommandSafetyLevel: String, Codable, Equatable, Sendable {
    case readOnly
    case workingTreeMutation
    case historyMutation
    case destructiveCleanup
    case credentialOrServerOperation
    case experimentalOrSpecialized

    /// Levels that must carry an explicit educational warning.
    var requiresWarning: Bool {
        switch self {
        case .readOnly, .workingTreeMutation:
            false
        case .historyMutation, .destructiveCleanup,
             .credentialOrServerOperation, .experimentalOrSpecialized:
            true
        }
    }
}

struct GitCommandChoice: Identifiable, Equatable, Sendable {
    let id: String
    let command: String
}

struct GitCommandLesson: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let objective: String
    let scenario: String
    let prompt: String
    let choices: [GitCommandChoice]
    let correctChoiceID: String
    let correctFeedback: String
    let incorrectFeedback: String
    let categoryID: String
    let sourceReferences: [String]
    let safetyLevel: GitCommandSafetyLevel
    let safetyWarning: String?

    var canonicalCommand: String {
        choices.first { $0.id == correctChoiceID }?.command ?? ""
    }
}

struct GitCommandCategory: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let lessons: [GitCommandLesson]
}

struct GitCommandCatalog: Equatable, Sendable {
    let sourceID: String
    let editionTitle: String
    let categories: [GitCommandCategory]

    var lessons: [GitCommandLesson] { categories.flatMap(\.lessons) }
    var lessonCount: Int { lessons.count }

    func lesson(id: String) -> GitCommandLesson? {
        lessons.first { $0.id == id }
    }

    func category(containing lessonID: String) -> GitCommandCategory? {
        categories.first { $0.lessons.contains { $0.id == lessonID } }
    }
}

enum GitCatalogError: LocalizedError, Equatable {
    case emptyCatalog
    case duplicateLessonID(String)
    case duplicateCommand(String)
    case missingChoices(String)
    case duplicateChoiceID(lesson: String, choice: String)
    case unknownCorrectChoice(String)
    case missingSourceReference(String)
    case missingSafetyWarning(String)

    var errorDescription: String? {
        switch self {
        case .emptyCatalog:
            "The Git catalog contains no lessons."
        case let .duplicateLessonID(id):
            "Duplicate Git lesson identifier: \(id)."
        case let .duplicateCommand(command):
            "Duplicate canonical Git command: \(command)."
        case let .missingChoices(id):
            "Git lesson \(id) needs at least two choices."
        case let .duplicateChoiceID(lesson, choice):
            "Git lesson \(lesson) repeats choice identifier \(choice)."
        case let .unknownCorrectChoice(id):
            "Git lesson \(id) has no choice matching its correct answer."
        case let .missingSourceReference(id):
            "Git lesson \(id) has no source reference."
        case let .missingSafetyWarning(id):
            "Git lesson \(id) needs a safety warning for its risk level."
        }
    }
}

/// Validates a decoded catalog before any of it reaches the learner.
struct ValidateGitCommandCatalogUseCase {
    func execute(_ catalog: GitCommandCatalog) throws {
        guard catalog.lessons.isEmpty == false else {
            throw GitCatalogError.emptyCatalog
        }

        var seenLessonIDs: Set<String> = []
        var seenCommands: Set<String> = []

        for lesson in catalog.lessons {
            guard seenLessonIDs.insert(lesson.id).inserted else {
                throw GitCatalogError.duplicateLessonID(lesson.id)
            }
            guard lesson.choices.count >= 2 else {
                throw GitCatalogError.missingChoices(lesson.id)
            }
            var seenChoiceIDs: Set<String> = []
            for choice in lesson.choices {
                guard seenChoiceIDs.insert(choice.id).inserted else {
                    throw GitCatalogError.duplicateChoiceID(
                        lesson: lesson.id,
                        choice: choice.id
                    )
                }
            }
            guard lesson.choices.contains(where: { $0.id == lesson.correctChoiceID })
            else {
                throw GitCatalogError.unknownCorrectChoice(lesson.id)
            }
            guard seenCommands.insert(lesson.canonicalCommand).inserted else {
                throw GitCatalogError.duplicateCommand(lesson.canonicalCommand)
            }
            guard lesson.sourceReferences.isEmpty == false else {
                throw GitCatalogError.missingSourceReference(lesson.id)
            }
            if lesson.safetyLevel.requiresWarning {
                let warning = lesson.safetyWarning?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                guard let warning, warning.isEmpty == false else {
                    throw GitCatalogError.missingSafetyWarning(lesson.id)
                }
            }
        }
    }
}
