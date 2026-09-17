//
//  SubmitLearningProjectUseCase.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

@MainActor
struct SubmitLearningProjectUseCase {
    private let loadProject: LoadLearningProjectUseCase
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let submissionRepository: any LearningProjectSubmissionRepository
    private let clock: any LearningClock
    private let attemptIDGenerator: any LearningAttemptIDGenerating
    private let submissionIDGenerator: any LearningProjectSubmissionIDGenerating

    init(
        loadProject: LoadLearningProjectUseCase,
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        submissionRepository: any LearningProjectSubmissionRepository,
        clock: any LearningClock,
        attemptIDGenerator: any LearningAttemptIDGenerating,
        submissionIDGenerator: any LearningProjectSubmissionIDGenerating
    ) {
        self.loadProject = loadProject
        self.loadCanonicalSkills = loadCanonicalSkills
        self.submissionRepository = submissionRepository
        self.clock = clock
        self.attemptIDGenerator = attemptIDGenerator
        self.submissionIDGenerator = submissionIDGenerator
    }

    func execute(
        projectID: String,
        responses: [LearningProjectResponse]
    ) throws -> LearningProjectSubmission {
        let availability = try loadProject.execute(projectID: projectID)
        guard availability.isUnlocked else {
            throw LearningProjectDomainError.projectLocked
        }

        let responsesByRequirement = try responses.reduce(
            into: [String: LearningProjectResponse]()
        ) { result, response in
            guard result[response.requirementID] == nil else {
                throw LearningProjectDomainError.duplicateResponse(
                    response.requirementID
                )
            }
            result[response.requirementID] = response
        }
        let requirementIDs = Set(availability.project.requirements.map(\.id))
        if let unknownID = responsesByRequirement.keys.first(
            where: { !requirementIDs.contains($0) }
        ) {
            throw LearningProjectDomainError.unknownRequirement(unknownID)
        }

        let canonicalSkills = try loadCanonicalSkills.execute()
        let timestamp = clock.now
        var results: [LearningProjectValidationResult] = []
        var attempts: [LearningAttempt] = []

        for requirement in availability.project.requirements {
            guard let response = responsesByRequirement[requirement.id] else {
                throw LearningProjectDomainError.missingResponse(requirement.id)
            }
            let activityResponse = LearningActivityResponse.choice(response.choiceID)
            guard requirement.lesson.activity.accepts(activityResponse) else {
                throw LearningProjectDomainError.choiceNotFound(requirement.id)
            }
            let activityID = LearningActivityID.project(
                projectID: availability.project.id,
                skillID: requirement.skillID
            )
            guard let skill = canonicalSkills.first(
                where: { $0.id == requirement.skillID }
            ), skill.lessonIDs.contains(requirement.lesson.id) else {
                throw LearningEvidenceDomainError.unknownSkillID(
                    requirement.skillID.rawValue
                )
            }
            guard skill.activityIDs.contains(activityID) else {
                throw LearningEvidenceDomainError.unknownActivityID(
                    activityID.rawValue
                )
            }

            let isCorrect = requirement.lesson.activity.isCorrect(activityResponse)
            let outcome: AttemptOutcome = isCorrect ? .correct : .incorrect
            results.append(
                LearningProjectValidationResult(
                    requirementID: requirement.id,
                    lessonID: requirement.lesson.id,
                    skillID: requirement.skillID,
                    selectedChoiceID: response.choiceID,
                    outcome: outcome,
                    feedback: isCorrect
                        ? requirement.lesson.correctFeedback
                        : requirement.lesson.incorrectFeedback
                )
            )
            attempts.append(
                LearningAttempt(
                    id: attemptIDGenerator.next(),
                    evidence: LearningEvidence(
                        lessonID: requirement.lesson.id,
                        skillID: requirement.skillID,
                        activityID: activityID,
                        outcome: outcome,
                        errorCategory: isCorrect ? nil : .incorrectChoice
                    ),
                    recordedAt: timestamp
                )
            )
        }

        let submission = LearningProjectSubmission(
            id: submissionIDGenerator.next(),
            projectID: availability.project.id,
            results: results,
            submittedAt: timestamp
        )
        try submissionRepository.record(submission, attempts: attempts)
        return submission
    }
}
