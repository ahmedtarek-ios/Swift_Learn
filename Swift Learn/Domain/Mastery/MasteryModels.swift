//
//  MasteryModels.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

enum MasteryLevel: String, CaseIterable, Equatable, Sendable {
    case unseen
    case introduced
    case practicing
    case reviewDue
    case proficient
    case mastered
}

struct SkillMasterySnapshot: Identifiable, Equatable, Sendable {
    let id: SkillID
    let level: MasteryLevel
    let correctAttemptCount: Int
    let incorrectAttemptCount: Int
    let lastAttemptAt: Date?
    let nextReviewAt: Date?
}

struct MasteryOverview: Equatable, Sendable {
    let snapshots: [SkillMasterySnapshot]

    var proficientCount: Int {
        snapshots.count { $0.level == .proficient || $0.level == .mastered }
    }

    var masteredCount: Int {
        snapshots.count { $0.level == .mastered }
    }

    var reviewDueCount: Int {
        snapshots.count { $0.level == .reviewDue }
    }
}

struct MasteryReviewPolicy: Equatable, Sendable {
    let incorrectDelay: TimeInterval
    let guidedCorrectDelays: [TimeInterval]
    let minimumRecallDelay: TimeInterval
    let minimumChallengeDelay: TimeInterval
    let overdueThreshold: TimeInterval
    let proficientCorrectCount: Int
    let proficientRecallCount: Int
    let proficientEvidenceSpan: TimeInterval
    let masteredCorrectCount: Int
    let masteredRecallCount: Int
    let masteredChallengeCount: Int
    let masteredEvidenceSpan: TimeInterval

    static let v1 = Self(
        incorrectDelay: 0,
        guidedCorrectDelays: [day, 3 * day, 7 * day, 30 * day],
        minimumRecallDelay: 3 * day,
        minimumChallengeDelay: 7 * day,
        overdueThreshold: day,
        proficientCorrectCount: 3,
        proficientRecallCount: 1,
        proficientEvidenceSpan: day,
        masteredCorrectCount: 5,
        masteredRecallCount: 2,
        masteredChallengeCount: 1,
        masteredEvidenceSpan: 7 * day
    )

    private static let day: TimeInterval = 86_400
}
