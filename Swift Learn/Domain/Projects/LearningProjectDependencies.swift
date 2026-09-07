//
//  LearningProjectDependencies.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation

@MainActor
protocol LearningProjectSubmissionIDGenerating {
    func next() -> UUID
}

@MainActor
struct SystemLearningProjectSubmissionIDGenerator: LearningProjectSubmissionIDGenerating {
    func next() -> UUID { UUID() }
}
