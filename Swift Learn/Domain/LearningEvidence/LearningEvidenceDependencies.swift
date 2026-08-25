//
//  LearningEvidenceDependencies.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

@MainActor
protocol LearningClock {
    var now: Date { get }
}

@MainActor
struct SystemLearningClock: LearningClock {
    var now: Date { .now }
}

@MainActor
protocol LearningAttemptIDGenerating {
    func next() -> UUID
}

@MainActor
struct SystemLearningAttemptIDGenerator: LearningAttemptIDGenerating {
    func next() -> UUID {
        UUID()
    }
}
