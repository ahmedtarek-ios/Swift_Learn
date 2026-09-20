import SwiftUI

struct WatchQuickReviewView: View {
    let viewModel: WatchQuickReviewViewModel
    let items: [WatchReviewItemSnapshot]
    let resetGeneration: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            switch viewModel.phase {
            case .idle:
                ProgressView("Preparing review")
                    .accessibilityIdentifier("watch-review-loading")
            case .reviewing:
                if let item = viewModel.currentItem {
                    WatchReviewQuestionView(
                        item: item,
                        viewModel: viewModel
                    )
                }
            case let .feedback(feedback):
                feedbackView(feedback)
            case .empty:
                emptyView
            case let .failed(message):
                errorView(message)
            }
        }
        .navigationTitle("Quick Review")
        .accessibilityIdentifier("watch-review-screen")
        .sensoryFeedback(.success, trigger: viewModel.successHapticSequence)
        .sensoryFeedback(.error, trigger: viewModel.errorHapticSequence)
        .task {
            viewModel.start(items: items, resetGeneration: resetGeneration)
        }
    }

    private func feedbackView(
        _ feedback: WatchQuickReviewViewModel.Feedback
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                feedback.isCorrect ? "Remembered" : "Review again",
                systemImage: feedback.isCorrect
                    ? "checkmark.circle.fill"
                    : "arrow.counterclockwise.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(feedback.isCorrect ? .green : .orange)
            .accessibilityIdentifier("watch-review-feedback")

            Text(feedback.message)
                .font(.body)
                .accessibilityIdentifier("watch-review-feedback-message")

            Label(
                pendingSummary,
                systemImage: "icloud.and.arrow.up.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
            .accessibilityIdentifier("watch-review-pending")

            if feedback.isCorrect {
                Button(feedback.isSessionComplete ? "Finish" : "Next Review") {
                    if feedback.isSessionComplete {
                        dismiss()
                    } else {
                        viewModel.continueToNextReview()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .accessibilityIdentifier(
                    feedback.isSessionComplete
                        ? "watch-review-finish"
                        : "watch-review-next"
                )
            } else {
                Button("Try Again", action: viewModel.retry)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .accessibilityIdentifier("watch-review-retry")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("You're caught up")
                .font(.headline)
            Text("New review work will appear after your next sync.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "You're caught up. New review work will appear after your next sync."
        )
        .accessibilityIdentifier("watch-review-empty")
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 10) {
            Label("Review unavailable", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: viewModel.retryAfterFailure)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("watch-review-error-retry")
        }
        .accessibilityIdentifier("watch-review-error")
    }

    private var pendingSummary: String {
        switch viewModel.pendingSyncEventCount {
        case 1:
            "1 change waiting to sync"
        default:
            "\(viewModel.pendingSyncEventCount) changes waiting to sync"
        }
    }
}

private struct WatchReviewQuestionView: View {
    let item: WatchReviewItemSnapshot
    let viewModel: WatchQuickReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.headline)
                .accessibilityIdentifier("watch-review-title")

            Text(item.prompt)
                .font(.body)
                .accessibilityIdentifier("watch-review-prompt")

            ForEach(item.choices) { choice in
                Button {
                    viewModel.selectChoice(choice.id)
                } label: {
                    HStack {
                        Text(choice.text)
                            .font(.body.monospaced())
                            .lineLimit(3)
                        Spacer(minLength: 4)
                        if viewModel.selectedChoiceID == choice.id {
                            Image(systemName: "checkmark.circle.fill")
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(
                    viewModel.selectedChoiceID == choice.id ? .orange : .secondary
                )
                .accessibilityLabel(choice.text)
                .accessibilityValue(
                    viewModel.selectedChoiceID == choice.id
                        ? "Selected"
                        : "Not selected"
                )
                .accessibilityIdentifier("watch-review-choice-\(choice.id)")
            }

            Button("Check Answer", action: viewModel.submit)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.canSubmit == false)
                .accessibilityIdentifier("watch-review-submit")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}
