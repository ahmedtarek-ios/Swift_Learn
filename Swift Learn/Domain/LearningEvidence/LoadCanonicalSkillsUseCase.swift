//
//  LoadCanonicalSkillsUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

@MainActor
struct LoadCanonicalSkillsUseCase {
    private let contentRepository: any LearningContentRepository
    private let skillRepository: any CanonicalSkillRepository

    init(
        contentRepository: any LearningContentRepository,
        skillRepository: any CanonicalSkillRepository
    ) {
        self.contentRepository = contentRepository
        self.skillRepository = skillRepository
    }

    func execute() throws -> [CanonicalSkill] {
        let catalog = try contentRepository.loadCatalog()
        let skills = try skillRepository.loadCanonicalSkills()
        let catalogLessonIDs = Set(catalog.lessons.map(\.id))
        let catalogActivityIDs = Set(catalog.lessons.map(\.activityID))
        var skillIDs = Set<SkillID>()
        var mappedLessonIDs = Set<String>()
        var mappedActivityIDs = Set<LearningActivityID>()

        for skill in skills {
            guard skillIDs.insert(skill.id).inserted else {
                throw LearningEvidenceDomainError.duplicateSkillID(skill.id.rawValue)
            }

            for lessonID in skill.lessonIDs {
                guard catalogLessonIDs.contains(lessonID) else {
                    throw LearningEvidenceDomainError.unknownMappedLesson(lessonID)
                }
                guard mappedLessonIDs.insert(lessonID).inserted else {
                    throw LearningEvidenceDomainError.duplicateLessonMapping(lessonID)
                }
            }

            for activityID in skill.activityIDs {
                let isOwnedReviewActivity = activityID == .review(skillID: skill.id)
                let isOwnedChallengeActivity = activityID == .challenge(skillID: skill.id)
                let isOwnedProjectActivity = activityID.isProjectActivity(for: skill.id)
                guard catalogActivityIDs.contains(activityID)
                        || isOwnedReviewActivity
                        || isOwnedChallengeActivity
                        || isOwnedProjectActivity else {
                    throw LearningEvidenceDomainError.unknownMappedActivity(
                        activityID.rawValue
                    )
                }
                guard mappedActivityIDs.insert(activityID).inserted else {
                    throw LearningEvidenceDomainError.duplicateActivityMapping(
                        activityID.rawValue
                    )
                }
            }
        }

        if let missingLessonID = catalog.lessons.lazy.map(\.id).first(
            where: { !mappedLessonIDs.contains($0) }
        ) {
            throw LearningEvidenceDomainError.missingLessonMapping(missingLessonID)
        }
        if let missingActivityID = catalog.lessons.lazy.map(\.activityID).first(
            where: { !mappedActivityIDs.contains($0) }
        ) {
            throw LearningEvidenceDomainError.missingActivityMapping(
                missingActivityID.rawValue
            )
        }

        return skills
    }
}
