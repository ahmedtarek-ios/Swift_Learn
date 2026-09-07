//
//  LearningProjectViewModel.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class LearningProjectViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let projectID: String
    private(set) var loadState: LoadState = .idle
    private(set) var availability: LearningProjectAvailability?
    private(set) var currentRequirementIndex = 0
    private(set) var selectedChoiceID: String?
    private(set) var responses: [LearningProjectResponse] = []
    private(set) var submission: LearningProjectSubmission?
    private(set) var errorMessage: String?
    private(set) var attemptRevision = 0

    private let loadProject: LoadLearningProjectUseCase
    private let submitProject: SubmitLearningProjectUseCase

    init(
        projectID: String,
        loadProject: LoadLearningProjectUseCase,
        submitProject: SubmitLearningProjectUseCase
    ) {
        self.projectID = projectID
        self.loadProject = loadProject
        self.submitProject = submitProject
    }

    func load() {
        loadState = .loading
        do {
            availability = try loadProject.execute(projectID: projectID)
            loadState = .loaded
        } catch {
            availability = nil
            loadState = .failed(error.localizedDescription)
        }
    }

    func startSession() {
        currentRequirementIndex = 0
        selectedChoiceID = nil
        responses = []
        submission = nil
        errorMessage = nil
    }

    func selectChoice(_ choiceID: String) {
        selectedChoiceID = choiceID
        errorMessage = nil
    }

    func continueProject() {
        guard let requirement = currentRequirement,
              let selectedChoiceID else {
            errorMessage = LearningProjectDomainError.choiceNotFound(
                currentRequirement?.id ?? projectID
            ).localizedDescription
            return
        }

        responses.append(
            LearningProjectResponse(
                requirementID: requirement.id,
                choiceID: selectedChoiceID
            )
        )
        self.selectedChoiceID = nil

        if currentRequirementIndex + 1 < requirementCount {
            currentRequirementIndex += 1
            return
        }

        do {
            submission = try submitProject.execute(
                projectID: projectID,
                responses: responses
            )
            attemptRevision += 1
            load()
        } catch {
            responses.removeLast()
            self.selectedChoiceID = selectedChoiceID
            errorMessage = error.localizedDescription
        }
    }

    var currentRequirement: LearningProjectRequirement? {
        guard let requirements = availability?.project.requirements,
              requirements.indices.contains(currentRequirementIndex),
              submission == nil else {
            return nil
        }
        return requirements[currentRequirementIndex]
    }

    var requirementCount: Int {
        availability?.project.requirements.count ?? 0
    }

    var stepSummary: String {
        guard requirementCount > 0 else { return "" }
        return "Requirement \(currentRequirementIndex + 1) of \(requirementCount)"
    }

    var primaryActionTitle: String {
        currentRequirementIndex + 1 == requirementCount
            ? "Submit Project"
            : "Save Requirement"
    }
}
