//
//  ContentCanonicalSkillRepository.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

@MainActor
final class ContentCanonicalSkillRepository: CanonicalSkillRepository {
    private let contentRepository: any LearningContentRepository

    init(contentRepository: any LearningContentRepository) {
        self.contentRepository = contentRepository
    }

    func loadCanonicalSkills() throws -> [CanonicalSkill] {
        try contentRepository.loadCatalog().lessons.map { lesson in
            CanonicalSkill(
                id: SkillID(rawValue: lesson.id),
                title: lesson.title,
                lessonIDs: [lesson.id],
                activityIDs: [
                    lesson.activityID,
                    .review(skillID: SkillID(rawValue: lesson.id))
                ]
            )
        }
    }
}
