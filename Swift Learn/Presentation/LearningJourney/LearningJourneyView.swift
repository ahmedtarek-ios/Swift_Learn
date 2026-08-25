//
//  LearningJourneyView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftUI

struct LearningJourneyView: View {
    @State private var viewModel: LearningJourneyViewModel
    private let reviewViewModel: ReviewQueueViewModel
    private let mistakeViewModel: MistakeNotebookViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    init(
        viewModel: LearningJourneyViewModel,
        reviewViewModel: ReviewQueueViewModel,
        mistakeViewModel: MistakeNotebookViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.reviewViewModel = reviewViewModel
        self.mistakeViewModel = mistakeViewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    ProgressView("Loading your journey…")
                        .accessibilityIdentifier("journey-loading")
                case .loaded:
                    journeyContent
                case let .failed(message):
                    ContentUnavailableView {
                        Label("Journey Unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again", action: viewModel.load)
                            .accessibilityIdentifier("retry-journey")
                    }
                }
            }
            .navigationTitle("Swift Learn")
        }
        .overlay {
            if let achievement = viewModel.currentAchievement {
                AchievementUnlockOverlay(
                    achievement: achievement,
                    reduceMotion: reduceMotion,
                    dismiss: viewModel.dismissCurrentAchievement
                )
                .transition(
                    reduceMotion
                        ? .opacity
                        : .scale(scale: 0.88).combined(with: .opacity)
                )
                .zIndex(10)
            }
        }
        .animation(
            LearningMotion.celebration(reduceMotion: reduceMotion),
            value: viewModel.currentAchievement?.id
        )
        .task(id: viewModel.attemptRevision) {
            if viewModel.loadState == .idle {
                viewModel.load()
            }
            reviewViewModel.load()
            mistakeViewModel.load()
        }
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }

    @ViewBuilder
    private var journeyContent: some View {
        if let journey = viewModel.journey {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sourceHeader(journey)
                    progressCard(journey)

                    ForEach(journey.catalog.levels) { level in
                        levelSection(level, journey: journey)
                    }
                }
                .frame(maxWidth: 840, alignment: .leading)
                .padding()
            }
            .accessibilityIdentifier("learning-journey")
        } else {
            ContentUnavailableView("No Lessons", systemImage: "book.closed")
        }
    }

    private func sourceHeader(_ journey: LearningJourney) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LEARN BY CODING")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text("Swift 6.4 beta")
                .font(.largeTitle.bold())
            Text("Change code. See why it works. Use it again later.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(journey.catalog.sourceID)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
        }
    }

    private func progressCard(_ journey: LearningJourney) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your progress")
                    .font(.headline)
                Spacer()
                Text("\(journey.completedLessonCount) / \(journey.totalLessonCount)")
                    .monospacedDigit()
            }
            ProgressView(value: journey.progress)
                .animation(
                    LearningMotion.progress(reduceMotion: reduceMotion),
                    value: journey.completedLessonCount
                )
            Text("\(journey.completedLessonCount) of \(journey.totalLessonCount) skills practiced")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(
                    LearningMotion.progress(reduceMotion: reduceMotion),
                    value: journey.completedLessonCount
                )
                .accessibilityIdentifier("journey-progress-summary")

            NavigationLink {
                ReviewQueueView(
                    viewModel: reviewViewModel,
                    mistakeViewModel: mistakeViewModel
                )
            } label: {
                Label(reviewViewModel.summary, systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("journey-review-summary")
            .accessibilityValue(reviewViewModel.summary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func levelSection(
        _ level: LearningLevel,
        journey: LearningJourney
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(level.title)
                .font(.title2.bold())
            Text(level.summary)
                .foregroundStyle(.secondary)

            ForEach(level.lessons) { lesson in
                let isUnlocked = journey.isUnlocked(lessonID: lesson.id)
                let isRecentlyUnlocked = viewModel.recentlyUnlockedLessonID == lesson.id
                NavigationLink {
                    LessonChallengeView(
                        lesson: lesson,
                        viewModel: viewModel
                    )
                } label: {
                    HStack(spacing: 14) {
                        Image(
                            systemName: journey.isCompleted(lessonID: lesson.id)
                                ? "checkmark.circle.fill"
                                : isUnlocked
                                    ? "chevron.left.forwardslash.chevron.right"
                                    : "lock.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            journey.isCompleted(lessonID: lesson.id)
                                ? Color.green
                                : Color.accentColor
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title)
                                .font(.headline)
                            Text(lesson.objective)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .background(
                        isRecentlyUnlocked
                            ? Color.accentColor.opacity(0.12)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isRecentlyUnlocked ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!isUnlocked)
                .accessibilityIdentifier("start-lesson-\(lesson.id)")
                .accessibilityValue(
                    journey.isCompleted(lessonID: lesson.id)
                        ? "Completed"
                        : isUnlocked ? "Available" : "Locked"
                )
                .animation(
                    LearningMotion.feedback(reduceMotion: reduceMotion),
                    value: isRecentlyUnlocked
                )
            }
        }
    }
}

private struct LessonChallengeView: View {
    let lesson: LearningLesson
    let viewModel: LearningJourneyViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("CODE CHALLENGE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(lesson.title)
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("lesson-title")
                Text(lesson.instruction)
                    .font(.title3)
                    .accessibilityIdentifier("lesson-instruction")

                CodeChoiceActivityView(
                    lesson: lesson,
                    selectedChoiceID: viewModel.selectedChoiceID,
                    codeIdentifier: "lesson-code",
                    choiceIdentifierPrefix: "choice-",
                    selectChoice: viewModel.selectChoice,
                    reduceMotion: reduceMotion
                )

                Button("Check Code") {
                    viewModel.submit(lessonID: lesson.id)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedChoiceID == nil)
                .accessibilityIdentifier("submit-answer")

                if let result = viewModel.attemptResult {
                    feedback(result)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(scale: 0.96, anchor: .top)
                                    .combined(with: .opacity)
                        )
                }

                Divider()
                Text("Source: \(lesson.sourceTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .navigationTitle("Practice")
        .onAppear(perform: viewModel.resetAttempt)
        .animation(
            LearningMotion.feedback(reduceMotion: reduceMotion),
            value: viewModel.attemptResult
        )
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }

    private func feedback(_ result: LessonAttemptResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                result.isCorrect ? "Lesson complete" : "Try another answer",
                systemImage: result.isCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise"
            )
            .font(.headline)
            .foregroundStyle(result.isCorrect ? Color.green : Color.orange)
            .accessibilityIdentifier(
                result.isCorrect ? "lesson-complete-feedback" : "lesson-retry-feedback"
            )
            .scaleEffect(result.isCorrect && !reduceMotion ? 1.03 : 1)
            .animation(
                LearningMotion.feedback(reduceMotion: reduceMotion),
                value: result.isCorrect
            )

            Text(result.feedback)

            if result.isCorrect,
               let progressSummary = viewModel.progressSummary {
                Text(progressSummary)
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel(progressSummary)
                    .accessibilityIdentifier("lesson-progress-summary")

                if let nextLesson = viewModel.nextLesson(after: lesson.id) {
                    NavigationLink("Continue to \(nextLesson.title)") {
                        LessonChallengeView(
                            lesson: nextLesson,
                            viewModel: viewModel
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("continue-next-lesson")
                }
            }
        }
        .padding()
        .background(
            (result.isCorrect ? Color.green : Color.orange).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

#Preview {
    let container = try! AppContainer(isStoredInMemoryOnly: true)
    LearningJourneyView(
        viewModel: container.learningJourneyViewModel,
        reviewViewModel: container.reviewQueueViewModel,
        mistakeViewModel: container.mistakeNotebookViewModel
    )
}
