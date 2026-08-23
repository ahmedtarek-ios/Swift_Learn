//
//  LearningJourneyView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftUI

struct LearningJourneyView: View {
    @State private var viewModel: LearningJourneyViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    init(viewModel: LearningJourneyViewModel) {
        _viewModel = State(initialValue: viewModel)
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
#if os(tvOS)
    @FocusState private var focusedChoiceID: String?
#endif

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

                codePanel

                Text("Choose the missing Swift code")
                    .font(.headline)

                choiceButtons

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
#if os(tvOS)
        .onAppear {
            focusedChoiceID = lesson.choices.first?.id
        }
#endif
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }

    private var codePanel: some View {
        Text(lesson.code(selectedChoiceID: viewModel.selectedChoiceID))
            .font(.system(.title3, design: .monospaced, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .contentTransition(.opacity)
            .animation(
                LearningMotion.selection(reduceMotion: reduceMotion),
                value: viewModel.selectedChoiceID
            )
            .accessibilityIdentifier("lesson-code")
    }

    private var choiceButtons: some View {
        HStack(spacing: 12) {
            ForEach(lesson.choices) { choice in
                Button {
                    viewModel.selectChoice(choice.id)
                } label: {
                    HStack {
                        Text(choice.code)
                            .font(.body.monospaced().weight(.semibold))
                        if viewModel.selectedChoiceID == choice.id {
                            Image(systemName: "checkmark")
                        }
                    }
                    .frame(minWidth: 90)
                }
                .buttonStyle(.bordered)
                .tint(
                    viewModel.selectedChoiceID == choice.id
                        ? Color.accentColor
                        : Color.secondary
                )
                .accessibilityIdentifier("choice-\(choice.id)")
                .accessibilityValue(
                    viewModel.selectedChoiceID == choice.id ? "Selected" : "Not selected"
                )
                .scaleEffect(
                    viewModel.selectedChoiceID == choice.id && !reduceMotion ? 1.04 : 1
                )
                .animation(
                    LearningMotion.selection(reduceMotion: reduceMotion),
                    value: viewModel.selectedChoiceID
                )
#if os(tvOS)
                .focused($focusedChoiceID, equals: choice.id)
#endif
            }
        }
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

            if result.isCorrect, let journey = viewModel.journey {
                Text("\(journey.completedLessonCount) of \(journey.totalLessonCount) skills practiced")
                    .font(.subheadline.weight(.semibold))
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
    LearningJourneyView(viewModel: container.learningJourneyViewModel)
}
