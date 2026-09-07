//
//  LearningProjectView.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import SwiftUI

struct LearningProjectView: View {
    let viewModel: LearningProjectViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("GUIDED PROJECT")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if let project = viewModel.availability?.project {
                    Text(project.title)
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("learning-project-title")
                    Text(project.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                if let submission = viewModel.submission {
                    submissionResult(submission)
                } else if let requirement = viewModel.currentRequirement {
                    requirementContent(requirement)
                } else if case let .failed(message) = viewModel.loadState {
                    ContentUnavailableView {
                        Label("Project Unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    }
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .navigationTitle("Guided Project")
        .onAppear(perform: viewModel.startSession)
    }

    private func requirementContent(
        _ requirement: LearningProjectRequirement
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.stepSummary)
                .font(.headline)
                .accessibilityIdentifier("project-step")
            Text(requirement.title)
                .font(.title2.bold())
                .accessibilityIdentifier("project-requirement-\(requirement.id)")
            Text(requirement.instruction)
                .foregroundStyle(.secondary)

            LearningActivityRenderer(
                activity: requirement.lesson.activity,
                selectedChoiceID: viewModel.selectedChoiceID,
                codeIdentifier: "project-code-\(requirement.id)",
                choiceIdentifierPrefix: "project-choice-\(requirement.id)-",
                selectChoice: viewModel.selectChoice,
                reduceMotion: reduceMotion
            )

            Button(viewModel.primaryActionTitle, action: viewModel.continueProject)
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedChoiceID == nil)
                .accessibilityIdentifier(
                    viewModel.currentRequirementIndex + 1 == viewModel.requirementCount
                        ? "submit-project"
                        : "save-project-requirement"
                )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("learning-project-error")
            }
        }
    }

    private func submissionResult(
        _ submission: LearningProjectSubmission
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                submission.isPassed ? "Project passed" : "Project submitted",
                systemImage: submission.isPassed
                    ? "checkmark.seal.fill"
                    : "arrow.clockwise.circle"
            )
            .font(.title.bold())
            .foregroundStyle(submission.isPassed ? Color.green : Color.orange)
            .accessibilityIdentifier(
                submission.isPassed
                    ? "learning-project-passed"
                    : "learning-project-needs-review"
            )

            Text(
                "\(submission.correctRequirementCount) of "
                    + "\(submission.results.count) requirements validated"
            )
            .font(.headline)
            .accessibilityIdentifier("learning-project-result-summary")

            Text(
                submission.isPassed
                    ? "Project evidence now contributes to your existing mastery record."
                    : "Missed requirements are now available to the review system."
            )
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            (submission.isPassed ? Color.green : Color.orange).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }
}
