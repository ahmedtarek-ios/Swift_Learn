//
//  LearningProject.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation

struct LearningProject: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let requirements: [LearningProjectRequirement]
}

struct LearningProjectRequirement: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let instruction: String
    let lesson: LearningLesson
    let skillID: SkillID
}

struct LearningProjectAvailability: Equatable, Sendable {
    let project: LearningProject
    let isUnlocked: Bool
    let completedRequirementCount: Int
    let totalRequirementCount: Int
    let latestSubmission: LearningProjectSubmission?
}

struct LearningProjectResponse: Equatable, Sendable {
    let requirementID: String
    let choiceID: String
}

struct LearningProjectValidationResult: Codable, Equatable, Sendable {
    let requirementID: String
    let lessonID: String
    let skillID: SkillID
    let selectedChoiceID: String
    let outcome: AttemptOutcome
    let feedback: String

    var isCorrect: Bool { outcome == .correct }
}

struct LearningProjectSubmission: Identifiable, Equatable, Sendable {
    let id: UUID
    let projectID: String
    let results: [LearningProjectValidationResult]
    let submittedAt: Date

    var isPassed: Bool {
        !results.isEmpty && results.allSatisfy(\.isCorrect)
    }

    var correctRequirementCount: Int {
        results.count(where: \.isCorrect)
    }
}

struct LearningProjectPolicy: Equatable, Sendable {
    let requirementCount: Int

    static let v1 = Self(requirementCount: 3)
}

enum LearningProjectDomainError: LocalizedError, Equatable {
    case projectNotFound(String)
    case insufficientRequirements(required: Int, available: Int)
    case projectLocked
    case missingResponse(String)
    case duplicateResponse(String)
    case unknownRequirement(String)
    case choiceNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .projectNotFound(id):
            "Unknown learning project: \(id)."
        case let .insufficientRequirements(required, available):
            "Project requires \(required) skills; only \(available) are available."
        case .projectLocked:
            "Complete the project's prerequisite lessons first."
        case let .missingResponse(id):
            "Project requirement has no response: \(id)."
        case let .duplicateResponse(id):
            "Project requirement has more than one response: \(id)."
        case let .unknownRequirement(id):
            "Unknown project requirement: \(id)."
        case let .choiceNotFound(id):
            "Choose a valid answer for project requirement: \(id)."
        }
    }
}
