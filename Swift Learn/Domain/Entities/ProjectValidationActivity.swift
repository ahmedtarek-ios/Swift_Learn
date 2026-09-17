//
//  ProjectValidationActivity.swift
//  Swift Learn
//

struct ProjectValidationActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let projectID: String
    let requirements: [LearningProjectRequirement]
    let submission: LearningProjectSubmission?

    init(project: LearningProject, submission: LearningProjectSubmission?) {
        schemaVersion = 1
        prompt = "Validate each guided-project requirement"
        projectID = project.id
        requirements = project.requirements
        self.submission = submission
    }

    func accepts(_ submitted: LearningProjectSubmission) -> Bool {
        guard submitted.projectID == projectID,
              submitted.results.count == requirements.count,
              Set(submitted.results.map(\.requirementID)).count == requirements.count else {
            return false
        }
        let results = Dictionary(uniqueKeysWithValues: submitted.results.map {
            ($0.requirementID, $0)
        })
        return requirements.allSatisfy { requirement in
            guard let result = results[requirement.id] else { return false }
            return result.lessonID == requirement.lesson.id
                && result.skillID == requirement.skillID
        }
    }

    var checklist: [ProjectValidationChecklistItem] {
        let validSubmission = submission.flatMap { accepts($0) ? $0 : nil }
        let results = Dictionary(uniqueKeysWithValues: (validSubmission?.results ?? []).map {
            ($0.requirementID, $0)
        })
        return requirements.map { requirement in
            let result = results[requirement.id]
            return ProjectValidationChecklistItem(
                id: requirement.id,
                title: requirement.title,
                status: result.map { $0.isCorrect ? .passed : .needsReview } ?? .pending,
                feedback: result?.feedback
            )
        }
    }
}

enum ProjectValidationStatus: Equatable, Sendable {
    case pending
    case passed
    case needsReview
}

struct ProjectValidationChecklistItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let status: ProjectValidationStatus
    let feedback: String?
}
