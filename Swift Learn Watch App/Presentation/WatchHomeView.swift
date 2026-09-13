import SwiftUI

struct WatchHomeView: View {
    @ObservedObject private var viewModel: WatchHomeViewModel

    init(viewModel: WatchHomeViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Syncing")
                        .accessibilityIdentifier("watch-sync-loading")
                case .empty:
                    WatchEmptyStateView()
                case let .loaded(content):
                    WatchSnapshotView(content: content)
                case let .failed(message):
                    WatchErrorStateView(message: message)
                }
            }
            .navigationTitle("Swift Learn")
        }
        .accessibilityIdentifier("watch-home")
        .task {
            await viewModel.observe()
        }
    }
}

private struct WatchSnapshotView: View {
    let content: WatchHomeViewModel.Content

    private var snapshot: WatchLearningSnapshot { content.snapshot }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Code Ascension", systemImage: "swift")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text("Hi, \(snapshot.learnerName)")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("watch-learner-name")

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.headline)
                        Spacer()
                        Text(snapshot.progress, format: .percent.precision(.fractionLength(0)))
                            .font(.headline.monospacedDigit())
                    }
                    ProgressView(value: snapshot.progress)
                        .tint(.orange)
                    Text(
                        "\(snapshot.completedLessonCount) of "
                            + "\(snapshot.totalLessonCount) lessons"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("watch-progress-summary")
                }
                .accessibilityElement(children: .combine)

                if let nextLesson = snapshot.nextLesson {
                    NavigationLink {
                        WatchNextLessonView(lesson: nextLesson)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Next Lesson", systemImage: "play.circle.fill")
                                .font(.caption.weight(.semibold))
                            Text(nextLesson.title)
                                .font(.body.weight(.semibold))
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .accessibilityIdentifier("watch-next-lesson")
                } else {
                    Label("Journey complete", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("watch-journey-complete")
                }

                Label {
                    Text(reviewSummary)
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                }
                .font(.callout.weight(.semibold))
                .accessibilityIdentifier("watch-review-count")

                Label(
                    syncSummary,
                    systemImage: content.pendingSyncEventCount == 0
                        ? "checkmark.icloud.fill"
                        : "icloud.and.arrow.up.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    content.pendingSyncEventCount == 0 ? .green : .orange
                )
                .accessibilityIdentifier("watch-sync-status")

                Text("Updated \(snapshot.generatedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("watch-sync-date")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .accessibilityIdentifier("watch-snapshot-content")
    }

    private var reviewSummary: String {
        switch snapshot.dueReviewCount {
        case 0:
            "No reviews due"
        case 1:
            "1 review due"
        default:
            "\(snapshot.dueReviewCount) reviews due"
        }
    }

    private var syncSummary: String {
        switch content.pendingSyncEventCount {
        case 0:
            "Synced"
        case 1:
            "1 change waiting to sync"
        default:
            "\(content.pendingSyncEventCount) changes waiting to sync"
        }
    }
}

private struct WatchNextLessonView: View {
    let lesson: WatchNextLessonSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "swift")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(lesson.title)
                    .font(.headline)
                    .accessibilityIdentifier("watch-next-lesson-title")
                Text(lesson.objective)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("watch-next-lesson-objective")
                Text("Continue the full exercise on iPhone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Next Lesson")
        .accessibilityIdentifier("watch-next-lesson-detail")
    }
}

private struct WatchEmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.title2)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("Open Swift Learn on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Your progress will appear after the first sync.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("watch-empty-state")
    }
}

private struct WatchErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("Sync unavailable")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("watch-sync-error")
    }
}
