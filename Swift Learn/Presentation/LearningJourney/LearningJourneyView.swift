//
//  LearningJourneyView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftUI

struct LearningJourneyView: View {
    @State private var viewModel: LearningJourneyViewModel
    @State private var bossChallengeViewModel: BossChallengeViewModel
    private let projectViewModel: LearningProjectViewModel
    private let reviewViewModel: ReviewQueueViewModel
    private let mistakeViewModel: MistakeNotebookViewModel
    private let discoveryViewModel: LearningDiscoveryViewModel
    private let supplementalViewModel: SupplementalTracksViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    init(
        viewModel: LearningJourneyViewModel,
        bossChallengeViewModel: BossChallengeViewModel,
        projectViewModel: LearningProjectViewModel,
        reviewViewModel: ReviewQueueViewModel,
        mistakeViewModel: MistakeNotebookViewModel,
        discoveryViewModel: LearningDiscoveryViewModel,
        supplementalViewModel: SupplementalTracksViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        _bossChallengeViewModel = State(initialValue: bossChallengeViewModel)
        self.projectViewModel = projectViewModel
        self.reviewViewModel = reviewViewModel
        self.mistakeViewModel = mistakeViewModel
        self.discoveryViewModel = discoveryViewModel
        self.supplementalViewModel = supplementalViewModel
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
        .id(viewModel.navigationRevision)
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
            bossChallengeViewModel.load()
            projectViewModel.load()
        }
        .onChange(of: bossChallengeViewModel.attemptRevision) {
            reviewViewModel.load()
            mistakeViewModel.load()
        }
        .onChange(of: projectViewModel.attemptRevision) {
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

            if let resumeLesson = journey.resumeLesson {
                NavigationLink {
                    LessonChallengeView(lesson: resumeLesson, viewModel: viewModel)
                } label: {
                    Label(
                        journey.completedLessonCount == 0
                            ? "Start with \(resumeLesson.title)"
                            : "Resume \(resumeLesson.title)",
                        systemImage: "play.circle.fill"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("resume-current-task")
                .accessibilityValue(resumeLesson.title)
            }

            NavigationLink {
                LearningDiscoveryView(
                    viewModel: discoveryViewModel,
                    supplementalViewModel: supplementalViewModel,
                    journeyViewModel: viewModel
                )
            } label: {
                Label("Discover Skills", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("open-learning-discovery")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func levelSection(
        _ level: LearningLevel,
        journey: LearningJourney
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink {
                LearningLevelDetailView(
                    level: level,
                    journeyViewModel: viewModel
                )
            } label: {
                HStack {
                    Text(level.title)
                        .font(.title2.bold())
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open-level-\(level.id)")
            Text(level.summary)
                .foregroundStyle(.secondary)

            if level.id == bossChallengeViewModel.levelID {
                bossChallengeCard
                learningProjectCard
            }

            ForEach(level.lessons) { lesson in
                let isUnlocked = journey.isUnlocked(lessonID: lesson.id)
                let isRecentlyUnlocked = viewModel.recentlyUnlockedLessonID == lesson.id
                NavigationLink {
                    LessonChallengeView(
                        lesson: lesson,
                        viewModel: viewModel
                    )
                } label: {
                    LearningLessonSummaryRow(
                        lesson: lesson,
                        availability: journey.availability(for: lesson.id),
                        isHighlighted: isRecentlyUnlocked
                    )
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

    @ViewBuilder
    private var bossChallengeCard: some View {
        switch bossChallengeViewModel.loadState {
        case .idle, .loading:
            ProgressView("Preparing boss challenge…")
                .accessibilityIdentifier("boss-challenge-loading")
        case .loaded:
            if let availability = bossChallengeViewModel.availability {
                NavigationLink {
                    BossChallengeView(viewModel: bossChallengeViewModel)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: availability.isUnlocked ? "crown.fill" : "lock.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Level Boss")
                                .font(.headline)
                            Text(
                                availability.isUnlocked
                                    ? "Combine two skills in one challenge"
                                    : "\(availability.completedRequirementCount) of "
                                        + "\(availability.totalRequirementCount) lessons complete"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .disabled(!availability.isUnlocked)
                .accessibilityIdentifier(
                    "start-boss-challenge-\(availability.challenge.levelID)"
                )
                .accessibilityValue(availability.isUnlocked ? "Available" : "Locked")
            }
        case let .failed(message):
            VStack(alignment: .leading, spacing: 8) {
                Text("Boss challenge unavailable")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Try Again", action: bossChallengeViewModel.load)
                    .accessibilityIdentifier("retry-boss-challenge")
            }
        }
    }

    @ViewBuilder
    private var learningProjectCard: some View {
        switch projectViewModel.loadState {
        case .idle, .loading:
            ProgressView("Preparing guided project…")
                .accessibilityIdentifier("learning-project-loading")
        case .loaded:
            if let availability = projectViewModel.availability {
                NavigationLink {
                    LearningProjectView(viewModel: projectViewModel)
                } label: {
                    HStack(spacing: 14) {
                        Image(
                            systemName: availability.isUnlocked
                                ? "hammer.fill"
                                : "lock.fill"
                        )
                        .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guided Project")
                                .font(.headline)
                            Text(
                                availability.isUnlocked
                                    ? availability.latestSubmission?.isPassed == true
                                        ? "Passed · Build it again to reinforce the skills"
                                        : "Apply three skills in one structured build"
                                    : "\(availability.completedRequirementCount) of "
                                        + "\(availability.totalRequirementCount) prerequisites complete"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .disabled(!availability.isUnlocked)
                .accessibilityIdentifier("start-learning-project-\(projectViewModel.projectID)")
                .accessibilityValue(availability.isUnlocked ? "Available" : "Locked")
            }
        case let .failed(message):
            VStack(alignment: .leading, spacing: 8) {
                Text("Guided project unavailable")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Try Again", action: projectViewModel.load)
                    .accessibilityIdentifier("retry-learning-project")
            }
        }
    }
}

private struct LearningLevelDetailView: View {
    let level: LearningLevel
    let journeyViewModel: LearningJourneyViewModel

    @ViewBuilder
    var body: some View {
        if let journey = journeyViewModel.journey {
            List {
                Section {
                    Text(level.summary)
                    let progress = journey.progress(for: level)
                    ProgressView(value: progress.progress)
                    Text("\(progress.completedLessonCount) of \(progress.totalLessonCount) lessons completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("level-progress-\(level.id)")
                }

                Section("Lessons") {
                    ForEach(level.lessons) { lesson in
                        NavigationLink {
                            LearningLessonAvailabilityView(
                                lesson: lesson,
                                journeyViewModel: journeyViewModel
                            )
                        } label: {
                            LearningLessonSummaryRow(
                                lesson: lesson,
                                availability: journey.availability(for: lesson.id),
                                isHighlighted: false
                            )
                        }
                        .accessibilityIdentifier("level-lesson-\(lesson.id)")
                    }
                }
            }
            .navigationTitle(level.title)
            .accessibilityIdentifier("level-detail-\(level.id)")
        } else {
            ContentUnavailableView("Level Unavailable", systemImage: "exclamationmark.triangle")
        }
    }
}

private struct LearningLessonAvailabilityView: View {
    let lesson: LearningLesson
    let journeyViewModel: LearningJourneyViewModel

    @ViewBuilder
    var body: some View {
        switch journeyViewModel.journey?.availability(for: lesson.id) {
        case .available, .completed:
            LessonChallengeView(lesson: lesson, viewModel: journeyViewModel)
        case let .locked(_, prerequisiteTitle):
            ContentUnavailableView {
                Label("Lesson Locked", systemImage: "lock.fill")
            } description: {
                Text("Complete “\(prerequisiteTitle)” first.")
            }
            .navigationTitle(lesson.title)
            .accessibilityIdentifier("locked-reason-\(lesson.id)")
        case .unavailable, nil:
            ContentUnavailableView("Lesson Unavailable", systemImage: "exclamationmark.triangle")
        }
    }
}

private struct LearningLessonSummaryRow: View {
    let lesson: LearningLesson
    let availability: LearningLessonAvailability
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(availability == .completed ? Color.green : Color.accentColor)
                .accessibilityHidden(true)
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
            isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }

    private var symbolName: String {
        switch availability {
        case .completed:
            "checkmark.circle.fill"
        case .available:
            "chevron.left.forwardslash.chevron.right"
        case .locked:
            "lock.fill"
        case .unavailable:
            "exclamationmark.triangle"
        }
    }
}

struct LessonChallengeView: View {
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

                LearningActivityRenderer(
                    activity: lesson.activity,
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
        bossChallengeViewModel: container.bossChallengeViewModel,
        projectViewModel: container.projectViewModel,
        reviewViewModel: container.reviewQueueViewModel,
        mistakeViewModel: container.mistakeNotebookViewModel,
        discoveryViewModel: container.learningDiscoveryViewModel,
        supplementalViewModel: container.supplementalTracksViewModel
    )
}
