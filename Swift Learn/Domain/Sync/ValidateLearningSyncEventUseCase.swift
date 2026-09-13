import Foundation

@MainActor
struct ValidateLearningSyncEventUseCase: LearningSyncEventValidating {
    private let contentRepository: any LearningContentRepository
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase

    init(
        contentRepository: any LearningContentRepository,
        loadCanonicalSkills: LoadCanonicalSkillsUseCase
    ) {
        self.contentRepository = contentRepository
        self.loadCanonicalSkills = loadCanonicalSkills
    }

    func validate(_ event: LearningSyncEvent) throws {
        switch event.kind {
        case .progressReset:
            throw LearningSyncValidationError.companionResetNotAllowed
        case .lessonCompleted:
            guard let lessonID = event.lessonID,
                  try contentRepository.loadCatalog().lesson(id: lessonID) != nil else {
                throw LearningSyncValidationError.unknownLesson(event.lessonID ?? "")
            }
            guard event.attempt == nil else {
                throw LearningSyncValidationError.unexpectedAttemptPayload
            }
        case .attemptRecorded:
            guard event.lessonID == nil else {
                throw LearningSyncValidationError.unexpectedLessonPayload
            }
            guard let attempt = event.attempt else {
                throw LearningSyncDomainError.missingAttempt
            }
            let skillID = SkillID(rawValue: attempt.skillID)
            let activityID = LearningActivityID(rawValue: attempt.activityID)
            guard let skill = try loadCanonicalSkills.execute().first(
                where: { $0.id == skillID }
            ) else {
                throw LearningSyncValidationError.unknownSkill(attempt.skillID)
            }
            guard skill.lessonIDs.contains(attempt.lessonID) else {
                throw LearningSyncValidationError.lessonDoesNotBelongToSkill(
                    attempt.lessonID
                )
            }
            guard skill.activityIDs.contains(activityID) else {
                throw LearningSyncValidationError.activityDoesNotBelongToSkill(
                    attempt.activityID
                )
            }
        }
    }
}

enum LearningSyncValidationError: LocalizedError, Equatable {
    case companionResetNotAllowed
    case unknownLesson(String)
    case unknownSkill(String)
    case lessonDoesNotBelongToSkill(String)
    case activityDoesNotBelongToSkill(String)
    case unexpectedAttemptPayload
    case unexpectedLessonPayload

    var errorDescription: String? {
        switch self {
        case .companionResetNotAllowed:
            "Apple Watch cannot reset learning progress."
        case let .unknownLesson(id):
            "Unknown synchronized lesson identifier: \(id)."
        case let .unknownSkill(id):
            "Unknown synchronized skill identifier: \(id)."
        case let .lessonDoesNotBelongToSkill(id):
            "Synchronized lesson does not belong to its skill: \(id)."
        case let .activityDoesNotBelongToSkill(id):
            "Synchronized activity does not belong to its skill: \(id)."
        case .unexpectedAttemptPayload:
            "Lesson completion event contains an unexpected attempt payload."
        case .unexpectedLessonPayload:
            "Attempt event contains an unexpected lesson payload."
        }
    }
}
