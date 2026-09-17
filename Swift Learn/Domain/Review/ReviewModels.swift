//
//  ReviewModels.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

enum ReviewStatus: String, Equatable, Sendable {
    case scheduled
    case due
    case overdue
}

struct ReviewItem: Identifiable, Equatable, Sendable {
    var id: SkillID { skill.id }

    let skill: CanonicalSkill
    let lesson: LearningLesson
    let mastery: SkillMasterySnapshot
    let dueAt: Date
    let status: ReviewStatus
}

struct MistakeNotebookEntry: Identifiable, Equatable, Sendable {
    var id: SkillID { skillID }

    let skillID: SkillID
    let title: String
    let attempts: [LearningAttempt]

    var latestErrorCategory: LearningErrorCategory? {
        attempts.sortedChronologically.last?.evidence.errorCategory
    }
}

enum ReviewDomainError: LocalizedError, Equatable {
    case reviewNotDue(String)
    case lessonUnavailable(String)
    case choiceNotFound
    case invalidActivityResponse

    var errorDescription: String? {
        switch self {
        case let .reviewNotDue(id):
            "Review is not due for skill: \(id)."
        case let .lessonUnavailable(id):
            "Review lesson is unavailable: \(id)."
        case .choiceNotFound:
            "Choose a valid review answer."
        case .invalidActivityResponse:
            "Complete the review activity with a valid answer."
        }
    }
}
