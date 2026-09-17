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
        try execute(skillID: skillID, response: .choice(choiceID))
    }

    func execute(
        skillID: SkillID,
        response: LearningActivityResponse
    ) throws -> LessonAttemptResult {
        guard let item = try loadReviewQueue.execute().first(where: { $0.id == skillID }) else {
            throw ReviewDomainError.reviewNotDue(skillID.rawValue)
        }
        guard item.lesson.activity.accepts(response) else {
            if case .choice = response {
                throw ReviewDomainError.choiceNotFound
            }
            throw ReviewDomainError.invalidActivityResponse
        }

        let isCorrect = item.lesson.activity.isCorrect(response)
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
