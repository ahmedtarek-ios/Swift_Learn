//
//  CompleteReviewUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

struct CompleteReviewUseCase {
    private let loadReviewQueue: LoadReviewQueueUseCase
    private let recordAttempt: RecordLearningAttemptUseCase

    init(
        loadReviewQueue: LoadReviewQueueUseCase,
        recordAttempt: RecordLearningAttemptUseCase
    ) {
        self.loadReviewQueue = loadReviewQueue
        self.recordAttempt = recordAttempt
    }

    func execute(skillID: SkillID, choiceID: String) throws -> LessonAttemptResult {
        guard let item = try loadReviewQueue.execute().first(where: { $0.id == skillID }) else {
            throw ReviewDomainError.reviewNotDue(skillID.rawValue)
        }
        guard item.lesson.choice(id: choiceID) != nil else {
            throw ReviewDomainError.choiceNotFound
        }

        let isCorrect = item.lesson.correctChoiceID == choiceID
        try recordAttempt.execute(
            lessonID: item.lesson.id,
            activityID: .review(skillID: skillID),
            outcome: isCorrect ? .correct : .incorrect
        )
        return LessonAttemptResult(
            isCorrect: isCorrect,
            feedback: isCorrect
                ? item.lesson.correctFeedback
                : item.lesson.incorrectFeedback
        )
    }
}
