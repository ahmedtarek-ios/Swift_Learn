import SwiftUI

struct GitLearningView: View {
    @State private var viewModel: GitLearningViewModel

    init(viewModel: GitLearningViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    ProgressView("Loading Git commands")
                        .accessibilityIdentifier("git-loading")
                case .empty:
                    ContentUnavailableView(
                        "No Git commands yet",
                        systemImage: "terminal",
                        description: Text("The Git catalog is empty.")
                    )
                    .accessibilityIdentifier("git-empty")
                case let .failed(message):
                    failureView(message)
                case .loaded:
                    loadedContent
                }
            }
            .navigationTitle("Git")
        }
        .accessibilityIdentifier("git-learning")
        .task {
            if viewModel.loadState == .idle {
                viewModel.load()
            }
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Git commands unavailable")
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { viewModel.load() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("retry-git-learning")
        }
        .padding()
        .accessibilityIdentifier("git-learning-error")
    }

    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let lesson = viewModel.currentLesson {
                    questionCard(lesson)
                } else if viewModel.isTrackComplete {
                    completionCard
                }
                categoryList
                resetSection
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GIT COMMANDS")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(viewModel.progressSummary)
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("git-progress-summary")
            if let track = viewModel.track {
                ProgressView(value: track.progress)
                    .tint(.orange)
                    .accessibilityHidden(true)
            }
            Text("Commands are shown as text only. Swift Learn never runs them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func questionCard(_ lesson: GitCommandLesson) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(lesson.title)
                .font(.headline)
                .accessibilityIdentifier("git-question-title")
            Text(lesson.scenario)
                .font(.body)
                .accessibilityIdentifier("git-question-scenario")
            Text(lesson.prompt)
                .font(.callout.weight(.semibold))
                .accessibilityIdentifier("git-question-instruction")

            if let warning = lesson.safetyWarning, lesson.safetyLevel.requiresWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("git-safety-warning")
                    .accessibilityLabel("Safety warning. \(warning)")
            }

            ForEach(lesson.choices) { choice in
                Button {
                    viewModel.select(choiceID: choice.id)
                } label: {
                    Text(choice.command)
                        .font(.body.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(viewModel.selectedChoiceID == choice.id ? .accentColor : .secondary)
                .disabled(viewModel.answerResult != nil)
                .accessibilityIdentifier("git-choice-\(choice.id)")
                .accessibilityValue(
                    viewModel.selectedChoiceID == choice.id ? "Selected" : "Not selected"
                )
            }

            if let result = viewModel.answerResult {
                feedback(result)
            } else {
                Button("Check Command") { viewModel.submit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSubmit)
                    .accessibilityIdentifier("submit-git-answer")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func feedback(_ result: GitAnswerResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                result.feedback,
                systemImage: result.isCorrect
                    ? "checkmark.seal.fill"
                    : "arrow.counterclockwise.circle.fill"
            )
            .foregroundStyle(result.isCorrect ? .green : .orange)
            .accessibilityIdentifier("git-answer-feedback")

            if result.isCorrect {
                Button(viewModel.nextLesson == nil ? "Finish Git Track" : "Next Command") {
                    viewModel.continueToNextQuestion()
                }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("continue-next-git-question")
            } else {
                Button("Try Again") { viewModel.retryCurrentQuestion() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("retry-git-question")
            }
        }
    }

    private var completionCard: some View {
        Label("Every Git command completed", systemImage: "checkmark.seal.fill")
            .font(.headline)
            .foregroundStyle(.green)
            .accessibilityIdentifier("git-track-complete")
    }

    @ViewBuilder
    private var categoryList: some View {
        if let track = viewModel.track {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(track.catalog.categories) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.title)
                            .font(.headline)
                        Text(category.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(category.lessons) { lesson in
                            Button {
                                viewModel.open(lessonID: lesson.id)
                            } label: {
                                HStack {
                                    Text(lesson.title)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(
                                        systemName: track.isCompleted(lessonID: lesson.id)
                                            ? "checkmark.circle.fill"
                                            : track.isUnlocked(lessonID: lesson.id)
                                                ? "play.circle"
                                                : "lock.fill"
                                    )
                                    .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(!track.isUnlocked(lessonID: lesson.id))
                            .accessibilityIdentifier("start-git-question-\(lesson.id)")
                            .accessibilityValue(
                                track.isCompleted(lessonID: lesson.id)
                                    ? "Completed"
                                    : track.isUnlocked(lessonID: lesson.id)
                                        ? "Available"
                                        : "Locked"
                            )
                        }
                    }
                }
            }
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            switch viewModel.resetState {
            case .resetting:
                ProgressView("Resetting Git progress")
                    .accessibilityIdentifier("git-progress-resetting")
            case .succeeded:
                Label("Git progress reset", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("git-progress-reset-success")
                Button("Done") { viewModel.acknowledgeResetOutcome() }
                    .accessibilityIdentifier("dismiss-git-reset-outcome")
            case let .failed(message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("git-progress-reset-error")
                Button("Done") { viewModel.acknowledgeResetOutcome() }
                    .accessibilityIdentifier("dismiss-git-reset-outcome")
            case .idle, .confirming:
                Button("Reset Git Progress", role: .destructive) {
                    viewModel.requestReset()
                }
                .accessibilityIdentifier("reset-git-progress")
            }
        }
        .alert(
            "Reset Git progress?",
            isPresented: Binding(
                get: { viewModel.resetState == .confirming },
                // Dismissal fires after the destructive action too; only a
                // real dismissal while confirming counts as a cancel.
                set: { isPresented in
                    if !isPresented, viewModel.resetState == .confirming {
                        viewModel.cancelReset()
                    }
                }
            )
        ) {
            Button("Reset Git Progress", role: .destructive) {
                viewModel.confirmReset()
            }
            .accessibilityIdentifier("confirm-reset-git-progress")
            Button("Cancel", role: .cancel) { viewModel.cancelReset() }
                .accessibilityIdentifier("cancel-reset-git-progress")
        } message: {
            Text("This clears Git commands only. Your Swift progress is preserved.")
        }
    }
}
