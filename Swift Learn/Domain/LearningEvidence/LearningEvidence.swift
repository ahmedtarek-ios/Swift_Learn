//
//  LearningEvidence.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

struct SkillID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String
}

struct LearningActivityID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    static func review(skillID: SkillID) -> Self {
        Self(rawValue: "review.\(skillID.rawValue)")
    }

    static func challenge(skillID: SkillID) -> Self {
        Self(rawValue: "challenge.\(skillID.rawValue)")
    }

    static func project(projectID: String, skillID: SkillID) -> Self {
        Self(rawValue: "project.\(projectID).\(skillID.rawValue)")
    }

    func isProjectActivity(for skillID: SkillID) -> Bool {
        rawValue.hasPrefix("project.")
            && rawValue.hasSuffix(".\(skillID.rawValue)")
    }

    var difficulty: LearningActivityDifficulty {
        if rawValue.hasPrefix("challenge.") || rawValue.hasPrefix("project.") {
            .challenge
        } else if rawValue.hasPrefix("review.") {
            .recall
        } else {
            .guided
        }
    }
}

enum LearningActivityDifficulty: String, Codable, Equatable, Sendable {
    case guided
    case recall
    case challenge
}

struct CanonicalSkill: Identifiable, Equatable, Sendable {
    let id: SkillID
    let title: String
    let lessonIDs: Set<String>
    let activityIDs: Set<LearningActivityID>
}

enum AttemptOutcome: String, Codable, Equatable, Sendable {
    case correct
    case incorrect
}

enum LearningErrorCategory: String, Codable, Equatable, Sendable {
    case incorrectChoice
    case syntax
    case typeMismatch
    case logic
    case testFailure
    case architectureBoundary
}

struct LearningEvidence: Equatable, Sendable {
    let lessonID: String
    let skillID: SkillID
    let activityID: LearningActivityID
    let outcome: AttemptOutcome
    let errorCategory: LearningErrorCategory?
}

struct LearningAttempt: Identifiable, Equatable, Sendable {
    let id: UUID
    let evidence: LearningEvidence
    let recordedAt: Date
}

enum LearningEvidenceDomainError: LocalizedError, Equatable {
    case unknownLessonID(String)
    case unknownActivityID(String)
    case unknownSkillID(String)
    case duplicateSkillID(String)
    case duplicateLessonMapping(String)
    case duplicateActivityMapping(String)
    case missingLessonMapping(String)
    case missingActivityMapping(String)
    case unknownMappedLesson(String)
    case unknownMappedActivity(String)

    var errorDescription: String? {
        switch self {
        case let .unknownLessonID(id):
            "Unknown lesson identifier: \(id)."
        case let .unknownActivityID(id):
            "Unknown activity identifier: \(id)."
        case let .unknownSkillID(id):
            "Unknown skill identifier: \(id)."
        case let .duplicateSkillID(id):
            "Duplicate skill identifier: \(id)."
        case let .duplicateLessonMapping(id):
            "Lesson maps to more than one skill: \(id)."
        case let .duplicateActivityMapping(id):
            "Activity maps to more than one skill: \(id)."
        case let .missingLessonMapping(id):
            "Lesson has no canonical skill mapping: \(id)."
        case let .missingActivityMapping(id):
            "Activity has no canonical skill mapping: \(id)."
        case let .unknownMappedLesson(id):
            "Canonical skill maps an unknown lesson: \(id)."
        case let .unknownMappedActivity(id):
            "Canonical skill maps an unknown activity: \(id)."
        }
    }
}
