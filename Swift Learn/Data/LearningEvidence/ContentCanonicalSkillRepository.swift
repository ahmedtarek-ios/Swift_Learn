//
//  ContentCanonicalSkillRepository.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import Foundation

@MainActor
final class ContentCanonicalSkillRepository: CanonicalSkillRepository {
    private let contentRepository: any LearningContentRepository
    private let projectRepository: (any LearningProjectRepository)?

    init(
        contentRepository: any LearningContentRepository,
        projectRepository: (any LearningProjectRepository)? = nil
    ) {
        self.contentRepository = contentRepository
        self.projectRepository = projectRepository
    }

    func loadCanonicalSkills() throws -> [CanonicalSkill] {
        let projects = try projectRepository?.loadProjects() ?? []
        return try contentRepository.loadCatalog().lessons.map { lesson in
            let skillID = SkillID(rawValue: lesson.id)
            let projectActivities: [LearningActivityID] = projects.flatMap { project in
                project.requirements.compactMap { requirement -> LearningActivityID? in
                    guard requirement.skillID == skillID else { return nil }
                    return LearningActivityID.project(
                        projectID: project.id,
                        skillID: skillID
                    )
                }
            }
            return CanonicalSkill(
                id: skillID,
                title: lesson.title,
                lessonIDs: [lesson.id],
                activityIDs: Set([
                    lesson.activityID,
                    .review(skillID: skillID),
                    .challenge(skillID: skillID)
                ] + projectActivities)
            )
        }
    }
}
