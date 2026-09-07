//
//  BossChallenge.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation

struct BossChallenge: Identifiable, Equatable, Sendable {
    let id: String
    let levelID: String
    let title: String
    let summary: String
    let items: [BossChallengeItem]
}

struct BossChallengeItem: Identifiable, Equatable, Sendable {
    let id: String
    let lesson: LearningLesson
    let skillID: SkillID
}

struct BossChallengeAvailability: Equatable, Sendable {
    let challenge: BossChallenge
    let isUnlocked: Bool
    let completedRequirementCount: Int
    let totalRequirementCount: Int
}

struct BossChallengeAnswerResult: Equatable, Sendable {
    let itemID: String
    let isCorrect: Bool
    let feedback: String
}

struct BossChallengeResult: Equatable, Sendable {
    let answers: [BossChallengeAnswerResult]

    var isPassed: Bool {
        !answers.isEmpty && answers.allSatisfy { $0.isCorrect }
    }

    var correctAnswerCount: Int {
        answers.count { $0.isCorrect }
    }
}

struct BossChallengeCompletion: Equatable, Sendable {
    let challengeID: String
    let levelID: String
    let completedAt: Date
}

struct BossChallengePolicy: Equatable, Sendable {
    let itemCount: Int

    static let v1 = Self(itemCount: 2)
}

enum BossChallengeDomainError: LocalizedError, Equatable {
    case levelNotFound(String)
    case insufficientSkills(required: Int, available: Int)
    case skillMappingNotFound(String)
    case challengeLocked
    case itemNotFound(String)
    case choiceNotFound
    case duplicateAnswer(String)
    case incompleteSession

    var errorDescription: String? {
        switch self {
        case let .levelNotFound(id):
            "Unknown learning level: \(id)."
        case let .insufficientSkills(required, available):
            "Boss challenge requires \(required) skills; only \(available) are available."
        case let .skillMappingNotFound(lessonID):
            "Boss challenge has no skill mapping for lesson: \(lessonID)."
        case .challengeLocked:
            "Complete every lesson in this level to unlock its boss challenge."
        case let .itemNotFound(id):
            "Unknown boss challenge item: \(id)."
        case .choiceNotFound:
            "Choose a valid challenge answer."
        case let .duplicateAnswer(itemID):
            "Boss challenge has more than one answer for: \(itemID)."
        case .incompleteSession:
            "Complete every boss challenge item before finishing the session."
        }
    }
}
