//
//  LearnerProfileViewModel.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class LearnerProfileViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    enum AvatarImportState: Equatable {
        case idle
        case importing
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var saveState: SaveState = .idle
    private(set) var snapshot: LearnerProfileSnapshot?
    private(set) var masteryOverview: MasteryOverview?
    private(set) var avatarImportState: AvatarImportState = .idle

    var draftDisplayName = LearnerProfile.defaultProfile.displayName
    var draftAvatar = LearnerProfile.defaultProfile.avatar
    var draftCustomAvatarImageData = LearnerProfile.defaultProfile.customAvatarImageData
    var draftAppearance = LearnerProfile.defaultProfile.appearance
    var draftMotionPreference = LearnerProfile.defaultProfile.motionPreference

    var progressSummary: String? {
        guard let snapshot else { return nil }
        return "\(snapshot.journey.completedLessonCount) of "
            + "\(snapshot.journey.totalLessonCount) lessons completed"
    }

    static func achievementAccessibilityValue(
        for achievement: AchievementProgress
    ) -> String {
        let status = achievement.isEarned ? "Earned" : "Locked"
        return "\(status), \(achievement.completedRequirementCount) of "
            + "\(achievement.totalRequirementCount)"
    }

    static func achievementAccessibilityLabel(
        for achievement: AchievementProgress
    ) -> String {
        let status = achievement.isEarned ? "Earned" : "Locked"
        return "\(achievement.definition.title), \(status)"
    }

    private let loadProfile: LoadLearnerProfileUseCase
    private let loadMasteryOverview: LoadMasteryOverviewUseCase
    private let updateProfile: UpdateLearnerProfileUseCase

    init(
        loadProfile: LoadLearnerProfileUseCase,
        loadMasteryOverview: LoadMasteryOverviewUseCase,
        updateProfile: UpdateLearnerProfileUseCase
    ) {
        self.loadProfile = loadProfile
        self.loadMasteryOverview = loadMasteryOverview
        self.updateProfile = updateProfile
    }

    func load() {
        loadState = .loading

        do {
            let snapshot = try loadProfile.execute()
            apply(snapshot)
            masteryOverview = try loadMasteryOverview.execute()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func save() {
        saveState = .saving

        do {
            _ = try updateProfile.execute(
                displayName: draftDisplayName,
                avatar: draftAvatar,
                customAvatarImageData: draftCustomAvatarImageData,
                appearance: draftAppearance,
                motionPreference: draftMotionPreference
            )
            let snapshot = try loadProfile.execute()
            apply(snapshot)
            masteryOverview = try loadMasteryOverview.execute()
            loadState = .loaded
            saveState = .saved
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    func selectBuiltInAvatar(_ avatar: LearnerAvatar) {
        guard avatar != .custom else { return }
        draftAvatar = avatar
        avatarImportState = .idle
    }

    func beginAvatarImport() {
        avatarImportState = .importing
    }

    func selectCustomAvatar(imageData: Data) {
        guard imageData.isEmpty == false else {
            avatarImportState = .failed("The selected image could not be loaded.")
            return
        }
        draftCustomAvatarImageData = imageData
        draftAvatar = .custom
        avatarImportState = .idle
    }

    func failAvatarImport(_ message: String) {
        avatarImportState = .failed(message)
    }

    private func apply(_ snapshot: LearnerProfileSnapshot) {
        self.snapshot = snapshot
        draftDisplayName = snapshot.profile.displayName
        draftAvatar = snapshot.profile.avatar
        draftCustomAvatarImageData = snapshot.profile.customAvatarImageData
        draftAppearance = snapshot.profile.appearance
        draftMotionPreference = snapshot.profile.motionPreference
    }
}
