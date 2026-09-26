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
    /// Bumped when the project being ordered changes. `startSession()` runs
    /// from `onAppear`, which SwiftUI may fire again for the same project.
    private(set) var choiceOrderRevision = 0
    private var orderedQuestionID: String?

    private let loadProject: LoadLearningProjectUseCase
    private let submitProject: SubmitLearningProjectUseCase
    private let orderChoices: OrderActivityChoicesUseCase

    init(
        projectID: String,
        loadProject: LoadLearningProjectUseCase,
        submitProject: SubmitLearningProjectUseCase,
        orderChoices: OrderActivityChoicesUseCase = OrderActivityChoicesUseCase(
            randomizer: IdentityChoiceOrder()
        )
    ) {
        self.projectID = projectID
        self.loadProject = loadProject
        self.submitProject = submitProject
        self.orderChoices = orderChoices
    }

    /// The answers for `requirement` in display order. Deterministic for a given
    /// requirement and `choiceOrderRevision`, so a redraw never reorders anything.
    func orderedChoices(
        for requirement: LearningProjectRequirement
    ) -> [LearningChoice] {
        orderChoices.execute(
            requirement.lesson.activity.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: requirement.id,
                attemptNumber: choiceOrderRevision
            )
        )
    }

    func orderedValidationChoices(
        for activity: LearningActivity
    ) -> [LearningChoice] {
        orderChoices.execute(
            activity.choices,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: projectID,
                attemptNumber: choiceOrderRevision
            )
        )
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

    /// Called from `onAppear`, which SwiftUI fires again for the project
    /// already on screen. Restarting then would discard requirements the
    /// learner has already answered, so only a new project starts a session.
    func startSession() {
        let questionID = availability?.project.requirements.first?.id
        guard orderedQuestionID != questionID || submission != nil else { return }
        orderedQuestionID = questionID
        choiceOrderRevision += 1
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

    var projectValidationActivity: LearningActivity? {
        guard let project = availability?.project else { return nil }
        return .projectValidation(
            ProjectValidationActivity(project: project, submission: submission)
        )
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
