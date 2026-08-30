//
//  LearnerProfileView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation
import ImageIO
import SwiftUI
#if !os(tvOS)
import PhotosUI
#endif

struct LearnerProfileView: View {
    @Bindable private var viewModel: LearnerProfileViewModel
#if !os(tvOS)
    @State private var selectedPhotoItem: PhotosPickerItem?
#endif
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
#if !os(tvOS)
        .task(id: selectedPhotoItem) {
            await importSelectedAvatar()
        }
#endif
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
#if os(tvOS)
            .defaultFocus($focusedControlID, "profile-avatar-unknown")
#endif
        }
    }

    private func profileEditor(_ snapshot: LearnerProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                CircularLearnerAvatar(
                    avatar: viewModel.draftAvatar,
                    customImageData: viewModel.draftCustomAvatarImageData,
                    size: 88
                )
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
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 72), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(LearnerAvatar.builtInCases) { avatar in
                        Button {
                            viewModel.selectBuiltInAvatar(avatar)
                        } label: {
                            avatarTile(
                                avatar,
                                customImageData: viewModel.draftCustomAvatarImageData,
                                isSelected: viewModel.draftAvatar == avatar
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(avatar.accessibilityLabel)
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
#if !os(tvOS)
                    let customAvatarImageData = viewModel.draftCustomAvatarImageData
                    let isCustomAvatarSelected = viewModel.draftAvatar == .custom
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        preferredItemEncoding: .current
                    ) {
                        ZStack(alignment: .bottomTrailing) {
                            avatarTile(
                                .custom,
                                customImageData: customAvatarImageData,
                                isSelected: isCustomAvatarSelected
                            )
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.accentColor)
                                .background(.background, in: Circle())
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Choose Memoji or photo")
                    .accessibilityHint("Opens your photo library")
                    .accessibilityIdentifier("profile-avatar-custom")
                    .accessibilityValue(
                        viewModel.draftAvatar == .custom ? "Selected" : "Not selected"
                    )
#endif
                }

                avatarImportFeedback
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

            if let progressSummary = viewModel.progressSummary {
                Text(progressSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(progressSummary)
                    .accessibilityIdentifier("profile-progress-summary")
            }

            if let mastery = viewModel.masteryOverview {
                Divider()
                HStack(spacing: 24) {
                    stat(value: mastery.proficientCount, label: "Proficient")
                    stat(value: mastery.masteredCount, label: "Mastered")
                    stat(value: mastery.reviewDueCount, label: "Review due")
                }
                Text(
                    "\(mastery.masteredCount) mastered, "
                        + "\(mastery.reviewDueCount) review due"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("profile-mastery-summary")
            }
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                LearnerProfileViewModel.achievementAccessibilityLabel(for: achievement)
            )
            .accessibilityIdentifier("achievement-card-\(achievement.id)")
            .accessibilityValue(
                LearnerProfileViewModel.achievementAccessibilityValue(for: achievement)
            )
            .accessibilityHint(achievement.definition.summary)
        }
    }

    private nonisolated func avatarTile(
        _ avatar: LearnerAvatar,
        customImageData: Data?,
        isSelected: Bool
    ) -> some View {
        CircularLearnerAvatar(
            avatar: avatar,
            customImageData: customImageData,
            size: 64
        )
        .padding(4)
        .overlay {
            Circle()
                .stroke(
                    isSelected ? Color.accentColor : .clear,
                    lineWidth: 4
                )
        }
    }

    @ViewBuilder
    private var avatarImportFeedback: some View {
        switch viewModel.avatarImportState {
        case .idle:
            EmptyView()
        case .importing:
            ProgressView("Loading avatar…")
                .accessibilityIdentifier("profile-avatar-importing")
        case let .failed(message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .accessibilityIdentifier("profile-avatar-import-error")
        }
    }

#if !os(tvOS)
    private func importSelectedAvatar() async {
        guard let selectedPhotoItem else { return }
        viewModel.beginAvatarImport()

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                viewModel.failAvatarImport("The selected image could not be loaded.")
                return
            }
            viewModel.selectCustomAvatar(imageData: data)
        } catch {
            viewModel.failAvatarImport(error.localizedDescription)
        }
    }
#endif

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

private struct CircularLearnerAvatar: View {
    let avatar: LearnerAvatar
    let customImageData: Data?
    let size: CGFloat

    var body: some View {
        avatarImage
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            }
            .contentShape(Circle())
    }

    private var avatarImage: Image {
        if avatar == .custom,
           let customImageData,
           let image = Self.thumbnail(from: customImageData) {
            return Image(decorative: image, scale: 1)
        }
        if let assetName = avatar.assetName {
            return Image(assetName)
        }
        return Image(systemName: "person.crop.circle.fill")
    }

    private static func thumbnail(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 512,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }
}

private extension LearnerAvatar {
    var assetName: String? {
        switch self {
        case .unknown:
            "avatar_unknown"
        case .boy:
            "avatar_boy"
        case .girl:
            "avatar_girl"
        case .man:
            "avatar_man"
        case .woman:
            "avatar_woman"
        case .grandfather:
            "avatar_gf"
        case .grandmother:
            "avatar_gm"
        case .custom:
            nil
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .unknown:
            "Mystery coder avatar"
        case .boy:
            "Boy coder avatar"
        case .girl:
            "Girl coder avatar"
        case .man:
            "Man coder avatar"
        case .woman:
            "Woman coder avatar"
        case .grandfather:
            "Grandfather coder avatar"
        case .grandmother:
            "Grandmother coder avatar"
        case .custom:
            "Custom Memoji or photo avatar"
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
