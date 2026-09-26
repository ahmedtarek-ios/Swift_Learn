import SwiftUI

struct GitLearningView: View {
    @State private var viewModel: GitLearningViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

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
                case let .loaded(track):
                    loadedContent(track)
                }
            }
            .navigationTitle("Git")
        }
        .id(viewModel.navigationRevision)
        .accessibilityIdentifier("git-learning")
        .task {
            if viewModel.loadState == .idle {
                viewModel.load()
            }
        }
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }

    private func failureView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Git Commands Unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: viewModel.load)
                .accessibilityIdentifier("retry-git-learning")
        }
        .accessibilityIdentifier("git-learning-error")
    }

    private func loadedContent(_ track: GitLearningTrack) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                GitTrackHeaderView(catalog: track.catalog)
                GitTrackProgressCard(
                    track: track,
                    viewModel: viewModel,
                    reduceMotion: reduceMotion
                )
                GitTrackResetSection(viewModel: viewModel)

                ForEach(track.catalog.categories) { category in
                    GitCategorySectionView(
                        category: category,
                        track: track,
                        viewModel: viewModel,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .accessibilityIdentifier("git-learning")
    }
}

private struct GitTrackHeaderView: View {
    let catalog: GitCommandCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LEARN GIT SAFELY")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(catalog.editionTitle)
                .font(.largeTitle.bold())
            Text("Choose the right command. Understand the risk. Practice without running it.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(catalog.sourceID)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
        }
        .accessibilityIdentifier("git-track-header")
    }
}

private struct GitTrackProgressCard: View {
    let track: GitLearningTrack
    let viewModel: GitLearningViewModel
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your progress")
                    .font(.headline)
                Spacer()
                Text("\(track.completedLessonCount) / \(track.totalLessonCount)")
                    .monospacedDigit()
            }

            ProgressView(value: track.progress)
                .tint(.orange)
                .animation(
                    LearningMotion.progress(reduceMotion: reduceMotion),
                    value: track.completedLessonCount
                )

            Text(viewModel.progressSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(
                    LearningMotion.progress(reduceMotion: reduceMotion),
                    value: track.completedLessonCount
                )
                .accessibilityIdentifier("git-progress-summary")

            if let resumeLesson = track.resumeLesson {
                NavigationLink {
                    GitCommandChallengeView(
                        lesson: resumeLesson,
                        viewModel: viewModel
                    )
                } label: {
                    Label(
                        track.completedLessonCount == 0
                            ? "Start with \(resumeLesson.title)"
                            : "Resume \(resumeLesson.title)",
                        systemImage: "play.circle.fill"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("resume-git-command")
                .accessibilityValue(resumeLesson.title)
            } else if track.isTrackComplete {
                Label("Every Git command completed", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("git-track-complete")
            }

            Text("Commands are shown as educational text only. Swift Learn never runs them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct GitTrackResetSection: View {
    let viewModel: GitLearningViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch viewModel.resetState {
            case .resetting:
                ProgressView("Resetting Git progress")
                    .accessibilityIdentifier("git-progress-resetting")
            case .succeeded:
                Label("Git progress reset", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Git progress reset")
                    .accessibilityIdentifier("git-progress-reset-success")
                Button("Done") { viewModel.acknowledgeResetOutcome() }
                    .accessibilityIdentifier("dismiss-git-reset-outcome")
            case let .failed(message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(message)
                    .accessibilityIdentifier("git-progress-reset-error")
                Button("Done") { viewModel.acknowledgeResetOutcome() }
                    .accessibilityIdentifier("dismiss-git-reset-outcome")
            case .idle, .confirming:
                Button("Reset Git Progress", role: .destructive) {
                    viewModel.requestReset()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("reset-git-progress")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .alert(
            "Reset Git progress?",
            isPresented: Binding(
                get: { viewModel.resetState == .confirming },
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

private struct GitCategorySectionView: View {
    let category: GitCommandCategory
    let track: GitLearningTrack
    let viewModel: GitLearningViewModel
    let reduceMotion: Bool

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            NavigationLink {
                GitCategoryDetailView(
                    category: category,
                    viewModel: viewModel
                )
            } label: {
                HStack {
                    Text(category.title)
                        .font(.title2.bold())
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open-git-category-\(category.id)")

            Text(category.summary)
                .foregroundStyle(.secondary)

            let categoryProgress = track.progress(for: category)
            Text(
                "\(categoryProgress.completedLessonCount) of "
                    + "\(categoryProgress.totalLessonCount) commands completed"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("git-category-progress-\(category.id)")

            ForEach(category.lessons) { lesson in
                let availability = track.availability(for: lesson.id)
                let isUnlocked = track.isUnlocked(lessonID: lesson.id)
                let isHighlighted = viewModel.recentlyUnlockedLessonID == lesson.id
                NavigationLink {
                    GitCommandChallengeView(
                        lesson: lesson,
                        viewModel: viewModel
                    )
                } label: {
                    GitCommandSummaryRow(
                        lesson: lesson,
                        availability: availability,
                        isHighlighted: isHighlighted
                    )
                }
                .buttonStyle(.bordered)
                .disabled(!isUnlocked)
                .accessibilityIdentifier("start-git-question-\(lesson.id)")
                .accessibilityValue(availability.accessibilityValue)
                .animation(
                    LearningMotion.feedback(reduceMotion: reduceMotion),
                    value: isHighlighted
                )
            }
        }
    }
}

private extension GitLessonAvailability {
    var accessibilityValue: String {
        switch self {
        case .completed:
            "Completed"
        case .available:
            "Available"
        case .locked:
            "Locked"
        case .unavailable:
            "Unavailable"
        }
    }
}

#Preview {
    let container = try! AppContainer(isStoredInMemoryOnly: true)
    GitLearningView(viewModel: container.gitLearningViewModel)
}
