//
//  LearnerProfileView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftUI

struct LearnerProfileView: View {
    @Bindable private var viewModel: LearnerProfileViewModel
#if os(tvOS)
    @FocusState private var focusedControlID: String?
#endif

    init(viewModel: LearnerProfileViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    ProgressView("Loading your profile…")
                        .accessibilityIdentifier("profile-loading")
                case .loaded:
                    profileContent
                case let .failed(message):
                    ContentUnavailableView {
                        Label("Profile Unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again", action: viewModel.load)
                            .accessibilityIdentifier("retry-profile")
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .onAppear(perform: viewModel.load)
        .onChange(of: viewModel.loadState) { _, state in
#if os(tvOS)
            if state == .loaded {
                focusedControlID = "profile-avatar-code"
            }
#endif
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        if let snapshot = viewModel.snapshot {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileEditor(snapshot)
                    progressSummary(snapshot)
                    achievementGrid(snapshot.achievements)
                }
                .frame(maxWidth: 1_000, alignment: .leading)
                .padding()
            }
            .accessibilityIdentifier("profile-screen")
        }
    }

    private func profileEditor(_ snapshot: LearnerProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                Image(systemName: avatarSymbol(viewModel.draftAvatar))
                    .font(.system(size: 38, weight: .bold))
                    .frame(width: 72, height: 72)
                    .foregroundStyle(.white)
                    .background(Color.accentColor.gradient, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Display name", text: $viewModel.draftDisplayName)
                        .font(.title2.bold())
#if !os(tvOS)
                        .textFieldStyle(.roundedBorder)
#endif
                        .accessibilityIdentifier("profile-display-name")
                    Text(snapshot.journey.catalog.editionTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Avatar")
                    .font(.headline)
                HStack(spacing: 10) {
                    ForEach(LearnerAvatar.allCases) { avatar in
                        Button {
                            viewModel.draftAvatar = avatar
                        } label: {
                            Image(systemName: avatarSymbol(avatar))
                                .frame(minWidth: 34, minHeight: 34)
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.draftAvatar == avatar ? .accentColor : .secondary)
                        .accessibilityLabel(avatarLabel(avatar))
                        .accessibilityIdentifier("profile-avatar-\(avatar.rawValue)")
                        .accessibilityValue(
                            viewModel.draftAvatar == avatar ? "Selected" : "Not selected"
                        )
#if os(tvOS)
                        .focused(
                            $focusedControlID,
                            equals: "profile-avatar-\(avatar.rawValue)"
                        )
#endif
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Motion")
                    .font(.headline)
                HStack(spacing: 10) {
                    ForEach(LearnerMotionPreference.allCases) { preference in
                        Button(motionPreferenceLabel(preference)) {
                            viewModel.draftMotionPreference = preference
                        }
                        .buttonStyle(.bordered)
                        .tint(
                            viewModel.draftMotionPreference == preference
                                ? .accentColor
                                : .secondary
                        )
                        .accessibilityIdentifier(
                            "profile-motion-\(preference.rawValue)"
                        )
                        .accessibilityValue(
                            viewModel.draftMotionPreference == preference
                                ? "Selected"
                                : "Not selected"
                        )
#if os(tvOS)
                        .focused(
                            $focusedControlID,
                            equals: "profile-motion-\(preference.rawValue)"
                        )
#endif
                    }
                }
                Text("Reduced motion replaces movement with immediate visual emphasis.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Appearance")
                    .font(.headline)
                HStack(spacing: 10) {
                    ForEach(LearnerAppearance.allCases) { appearance in
                        Button(appearanceLabel(appearance)) {
                            viewModel.draftAppearance = appearance
                        }
                        .buttonStyle(.bordered)
                        .tint(
                            viewModel.draftAppearance == appearance
                                ? .accentColor
                                : .secondary
                        )
                        .accessibilityIdentifier(
                            "profile-appearance-\(appearance.rawValue)"
                        )
                        .accessibilityValue(
                            viewModel.draftAppearance == appearance
                                ? "Selected"
                                : "Not selected"
                        )
#if os(tvOS)
                        .focused(
                            $focusedControlID,
                            equals: "profile-appearance-\(appearance.rawValue)"
                        )
#endif
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Save Profile", action: viewModel.save)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.saveState == .saving)
                    .accessibilityIdentifier("save-profile")
#if os(tvOS)
                    .focused($focusedControlID, equals: "save-profile")
#endif

                switch viewModel.saveState {
                case .idle:
                    EmptyView()
                case .saving:
                    ProgressView()
                        .accessibilityLabel("Saving profile")
                case .saved:
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("profile-save-success")
                case let .failed(message):
                    Text(message)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("profile-save-error")
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func progressSummary(_ snapshot: LearnerProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning progress")
                .font(.title2.bold())

            ProgressView(value: snapshot.journey.progress)

            HStack(spacing: 24) {
                stat(
                    value: snapshot.journey.completedLessonCount,
                    label: "Lessons"
                )
                stat(
                    value: snapshot.completedLevelCount,
                    label: "Levels"
                )
                stat(
                    value: snapshot.earnedAchievementCount,
                    label: "Badges"
                )
            }

            Text(
                "\(snapshot.journey.completedLessonCount) of "
                    + "\(snapshot.journey.totalLessonCount) lessons completed"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("profile-progress-summary")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value, format: .number)
                .font(.title.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func achievementGrid(_ achievements: [AchievementProgress]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Achievements")
                    .font(.title2.bold())
                Spacer()
                Text("\(achievements.filter(\.isEarned).count) / \(achievements.count)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("profile-achievement-summary")
            }

            achievementCollection(achievements)
        }
    }

    @ViewBuilder
    private func achievementCollection(_ achievements: [AchievementProgress]) -> some View {
#if os(tvOS)
        VStack(spacing: 14) {
            achievementLinks(achievements)
        }
#else
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220), spacing: 14)],
            spacing: 14
        ) {
            achievementLinks(achievements)
        }
#endif
    }

    @ViewBuilder
    private func achievementLinks(_ achievements: [AchievementProgress]) -> some View {
        ForEach(achievements) { achievement in
            NavigationLink {
                AchievementDetailView(achievement: achievement)
            } label: {
                AchievementCard(achievement: achievement)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("achievement-card-\(achievement.id)")
            .accessibilityValue(
                achievement.isEarned
                    ? "Earned, \(achievement.completedRequirementCount) of \(achievement.totalRequirementCount)"
                    : "Locked, \(achievement.completedRequirementCount) of \(achievement.totalRequirementCount)"
            )
        }
    }

    private func avatarSymbol(_ avatar: LearnerAvatar) -> String {
        switch avatar {
        case .code:
            "chevron.left.forwardslash.chevron.right"
        case .terminal:
            "terminal.fill"
        case .book:
            "book.fill"
        case .star:
            "star.fill"
        }
    }

    private func avatarLabel(_ avatar: LearnerAvatar) -> String {
        switch avatar {
        case .code:
            "Code avatar"
        case .terminal:
            "Terminal avatar"
        case .book:
            "Book avatar"
        case .star:
            "Star avatar"
        }
    }

    private func appearanceLabel(_ appearance: LearnerAppearance) -> String {
        switch appearance {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    private func motionPreferenceLabel(_ preference: LearnerMotionPreference) -> String {
        switch preference {
        case .system:
            "System Motion"
        case .reduced:
            "Reduced Motion"
        }
    }
}

private struct AchievementCard: View {
    let achievement: AchievementProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: achievementSymbol)
                    .font(.title2.bold())
                    .foregroundStyle(achievement.isEarned ? Color.yellow : Color.secondary)
                Spacer()
                Label(
                    achievement.isEarned ? "Earned" : "Locked",
                    systemImage: achievement.isEarned ? "checkmark.circle.fill" : "lock.fill"
                )
                .font(.caption.bold())
            }

            Text(achievement.definition.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(achievement.definition.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            ProgressView(value: achievement.progress)
            Text(
                "\(achievement.completedRequirementCount) / "
                    + "\(achievement.totalRequirementCount)"
            )
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    achievement.isEarned ? Color.yellow.opacity(0.7) : Color.secondary.opacity(0.2),
                    lineWidth: achievement.isEarned ? 2 : 1
                )
        }
    }

    private var achievementSymbol: String {
        switch achievement.definition.kind {
        case .firstLesson:
            "1.circle.fill"
        case .firstLevel:
            "flag.checkered"
        case .lessonMilestone:
            "bolt.fill"
        case .level:
            "medal.fill"
        case .sourceCompletion:
            "trophy.fill"
        }
    }
}

private struct AchievementDetailView: View {
    let achievement: AchievementProgress

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: achievement.isEarned ? "medal.fill" : "lock.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(achievement.isEarned ? Color.yellow : Color.secondary)
                Text(achievement.definition.title)
                    .font(.largeTitle.bold())
                Text(achievement.definition.summary)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                ProgressView(value: achievement.progress)
                Text(
                    achievement.isEarned
                        ? "Earned"
                        : "\(achievement.completedRequirementCount) of \(achievement.totalRequirementCount) completed"
                )
                .font(.headline)
                .accessibilityIdentifier("achievement-detail-status")
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding()
        }
        .navigationTitle("Achievement")
    }
}
