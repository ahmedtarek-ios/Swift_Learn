//
//  SubmitLessonAnswerUseCase.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
struct SubmitLessonAnswerUseCase {
    private let contentRepository: any LearningContentRepository
    private let progressRepository: any LearningProgressRepository

    init(
        contentRepository: any LearningContentRepository,
        progressRepository: any LearningProgressRepository
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
    }

    func execute(lessonID: String, choiceID: String) throws -> LessonAttemptResult {
        let catalog = try contentRepository.loadCatalog()
        guard let lesson = catalog.lesson(id: lessonID) else {
            throw LearningDomainError.lessonNotFound
        }
        let journey = LearningJourney(
            catalog: catalog,
            completedLessonIDs: try progressRepository.loadCompletedLessonIDs()
        )
        guard journey.isUnlocked(lessonID: lessonID) else {
            throw LearningDomainError.lessonLocked
        }
        guard lesson.choice(id: choiceID) != nil else {
            throw LearningDomainError.choiceNotFound
        }

        let isCorrect = lesson.correctChoiceID == choiceID
        if isCorrect {
            try progressRepository.markCompleted(lessonID: lessonID)
        }

        return LessonAttemptResult(
            isCorrect: isCorrect,
            feedback: isCorrect ? lesson.correctFeedback : lesson.incorrectFeedback
        )
    }
}
