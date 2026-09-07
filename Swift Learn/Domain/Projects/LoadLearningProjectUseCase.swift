//
//  LoadLearningProjectUseCase.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

@MainActor
struct LoadLearningProjectUseCase {
    private let projectRepository: any LearningProjectRepository
    private let progressRepository: any LearningProgressRepository
    private let submissionRepository: any LearningProjectSubmissionRepository
    private let policy: LearningProjectPolicy

    init(
        projectRepository: any LearningProjectRepository,
        progressRepository: any LearningProgressRepository,
        submissionRepository: any LearningProjectSubmissionRepository,
        policy: LearningProjectPolicy = .v1
    ) {
        self.projectRepository = projectRepository
        self.progressRepository = progressRepository
        self.submissionRepository = submissionRepository
        self.policy = policy
    }

    func execute(projectID: String) throws -> LearningProjectAvailability {
        guard let project = try projectRepository.loadProjects().first(
            where: { $0.id == projectID }
        ) else {
            throw LearningProjectDomainError.projectNotFound(projectID)
        }
        guard project.requirements.count == policy.requirementCount else {
            throw LearningProjectDomainError.insufficientRequirements(
                required: policy.requirementCount,
                available: project.requirements.count
            )
        }

        let completedLessonIDs = try progressRepository.loadCompletedLessonIDs()
        let completedCount = project.requirements.count {
            completedLessonIDs.contains($0.lesson.id)
        }
        return LearningProjectAvailability(
            project: project,
            isUnlocked: completedCount == project.requirements.count,
            completedRequirementCount: completedCount,
            totalRequirementCount: project.requirements.count,
            latestSubmission: try submissionRepository.loadLatestSubmission(
                projectID: project.id
            )
        )
    }
}
