//
//  RecordLearningAttemptUseCase.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

@MainActor
struct RecordLearningAttemptUseCase {
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository
    private let clock: any LearningClock
    private let idGenerator: any LearningAttemptIDGenerating

    init(
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository,
        clock: any LearningClock,
        idGenerator: any LearningAttemptIDGenerating
    ) {
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
        self.clock = clock
        self.idGenerator = idGenerator
    }

    @discardableResult
    func execute(
        lessonID: String,
        activityID: LearningActivityID,
        outcome: AttemptOutcome,
        errorCategory: LearningErrorCategory? = nil
    ) throws -> LearningAttempt {
        let skills = try loadCanonicalSkills.execute()
        guard let skill = skills.first(where: { $0.lessonIDs.contains(lessonID) }) else {
            throw LearningEvidenceDomainError.unknownLessonID(lessonID)
        }
        guard skill.activityIDs.contains(activityID) else {
            throw LearningEvidenceDomainError.unknownActivityID(activityID.rawValue)
        }

        let evidence = LearningEvidence(
            lessonID: lessonID,
            skillID: skill.id,
            activityID: activityID,
            outcome: outcome,
            errorCategory: outcome == .correct
                ? nil
                : errorCategory ?? .incorrectChoice
        )
        let attempt = LearningAttempt(
            id: idGenerator.next(),
            evidence: evidence,
            recordedAt: clock.now
        )
        try attemptRepository.record(attempt)
        return attempt
    }
}
