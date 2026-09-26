import SwiftUI

struct GitCommandChallengeView: View {
    let lesson: GitCommandLesson
    let viewModel: GitLearningViewModel
    @FocusState private var focusedChoiceID: String?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    /// Display order for this question, decided by Domain.
    private var orderedChoices: [GitCommandChoice] {
        viewModel.orderedChoices(for: lesson)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("GIT CHALLENGE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(lesson.title)
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("git-question-title")
                Text(lesson.objective)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(lesson.scenario)
                    .font(.body)
                    .accessibilityIdentifier("git-question-scenario")
                Text(lesson.prompt)
                    .font(.headline)
                    .accessibilityIdentifier("git-question-instruction")

                if let warning = lesson.safetyWarning, lesson.safetyLevel.requiresWarning {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("git-safety-warning")
                        .accessibilityLabel("Safety warning. \(warning)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(orderedChoices) { choice in
                        Button {
                            viewModel.select(choiceID: choice.id)
                        } label: {
                            Text(choice.command)
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .tint(
                            viewModel.selectedChoiceID == choice.id
                                ? Color.accentColor
                                : Color.secondary
                        )
                        .disabled(viewModel.answerResult != nil)
#if os(macOS)
                        .focusable()
#endif
                        .focused($focusedChoiceID, equals: choice.id)
                        .accessibilityIdentifier("git-choice-\(choice.id)")
                        .accessibilityValue(
                            viewModel.selectedChoiceID == choice.id
                                ? "Selected"
                                : "Not selected"
                        )
                    }
                }
                .defaultFocus($focusedChoiceID, orderedChoices.first?.id)

                Button("Check Command") {
                    viewModel.submit(lessonID: lesson.id)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit(lessonID: lesson.id))
#if os(macOS)
                .focusable()
                .focused($focusedChoiceID, equals: "__submit-git-answer")
#endif
                .accessibilityIdentifier("submit-git-answer")

                if let result = viewModel.answerResult {
                    feedback(result)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(scale: 0.96, anchor: .top)
                                    .combined(with: .opacity)
                        )
                }

                Divider()
                ForEach(lesson.sourceReferences, id: \.self) { reference in
                    Text("Source: \(reference)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .navigationTitle("Git Practice")
        .accessibilityIdentifier("git-command-challenge-\(lesson.id)")
        .onAppear {
            viewModel.beginLesson(id: lesson.id)
        }
        .animation(
            LearningMotion.feedback(reduceMotion: reduceMotion),
            value: viewModel.answerResult
        )
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }

    private func feedback(_ result: GitAnswerResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                result.isCorrect ? "Command complete" : "Try another command",
                systemImage: result.isCorrect
                    ? "checkmark.circle.fill"
                    : "arrow.counterclockwise"
            )
            .font(.headline)
            .foregroundStyle(result.isCorrect ? Color.green : Color.orange)
            .accessibilityIdentifier("git-answer-feedback")

            Text(result.feedback)

            Text(viewModel.progressSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .accessibilityIdentifier("git-progress-summary")

            if result.isCorrect {
                if let nextLesson = viewModel.nextLesson(after: lesson.id) {
                    NavigationLink("Continue to \(nextLesson.title)") {
                        GitCommandChallengeView(
                            lesson: nextLesson,
                            viewModel: viewModel
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("continue-next-git-question")
                } else {
                    Button("Finish Git Track") {
                        viewModel.finishTrack()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("continue-next-git-question")
                }
            } else {
                Button("Try Again") {
                    viewModel.retryCurrentQuestion()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("retry-git-question")
            }
        }
        .padding()
        .background(
            (result.isCorrect ? Color.green : Color.orange).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}
