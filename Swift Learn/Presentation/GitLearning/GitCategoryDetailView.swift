import SwiftUI

struct GitCategoryDetailView: View {
    let category: GitCommandCategory
    let viewModel: GitLearningViewModel

    @ViewBuilder
    var body: some View {
        if let track = viewModel.track {
            let categoryProgress = track.progress(for: category)
            List {
                Section {
                    Text(category.summary)
                    ProgressView(value: categoryProgress.progress)
                        .tint(.orange)
                    Text(
                        "\(categoryProgress.completedLessonCount) of "
                            + "\(categoryProgress.totalLessonCount) commands completed"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("git-category-progress-\(category.id)")
                }

                Section("Commands") {
                    ForEach(category.lessons) { lesson in
                        let availability = track.availability(for: lesson.id)
                        NavigationLink {
                            GitCommandAvailabilityView(
                                lesson: lesson,
                                availability: availability,
                                viewModel: viewModel
                            )
                        } label: {
                            GitCommandSummaryRow(
                                lesson: lesson,
                                availability: availability,
                                isHighlighted: false
                            )
                        }
                        .accessibilityIdentifier("git-command-row-\(lesson.id)")
                        .accessibilityValue(availability.detailAccessibilityValue)
                    }
                }
            }
            .navigationTitle(category.title)
            .accessibilityIdentifier("git-category-detail-\(category.id)")
        } else {
            ContentUnavailableView(
                "Git Category Unavailable",
                systemImage: "exclamationmark.triangle"
            )
        }
    }
}

private struct GitCommandAvailabilityView: View {
    let lesson: GitCommandLesson
    let availability: GitLessonAvailability
    let viewModel: GitLearningViewModel

    @ViewBuilder
    var body: some View {
        switch availability {
        case .available, .completed:
            GitCommandChallengeView(lesson: lesson, viewModel: viewModel)
        case let .locked(_, prerequisiteTitle):
            ContentUnavailableView {
                Label("Command Locked", systemImage: "lock.fill")
            } description: {
                Text("Complete “\(prerequisiteTitle)” first.")
            }
            .navigationTitle(lesson.title)
            .accessibilityIdentifier("git-command-locked-reason-\(lesson.id)")
        case .unavailable:
            ContentUnavailableView(
                "Command Unavailable",
                systemImage: "exclamationmark.triangle"
            )
        }
    }
}

private extension GitLessonAvailability {
    var detailAccessibilityValue: String {
        switch self {
        case .completed:
            "Completed"
        case .available:
            "Available"
        case let .locked(_, prerequisiteTitle):
            "Locked. Complete \(prerequisiteTitle) first."
        case .unavailable:
            "Unavailable"
        }
    }
}
