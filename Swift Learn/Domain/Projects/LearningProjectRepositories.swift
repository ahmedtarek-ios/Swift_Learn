//
//  LearningProjectRepositories.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

@MainActor
protocol LearningProjectRepository {
    func loadProjects() throws -> [LearningProject]
}

@MainActor
protocol LearningProjectSubmissionRepository {
    func record(
        _ submission: LearningProjectSubmission,
        attempts: [LearningAttempt]
    ) throws
    func loadLatestSubmission(projectID: String) throws -> LearningProjectSubmission?
    func loadSubmissions(projectID: String) throws -> [LearningProjectSubmission]
}
