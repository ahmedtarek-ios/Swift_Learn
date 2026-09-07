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

    enum ResetState: Equatable {
        case idle
        case resetting
        case reset
        case failed(String)
    }

    enum RecentActivityState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum ExperienceAchievementState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var saveState: SaveState = .idle
    private(set) var snapshot: LearnerProfileSnapshot?
    private(set) var masteryOverview: MasteryOverview?
    private(set) var avatarImportState: AvatarImportState = .idle
    private(set) var resetState: ResetState = .idle
    private(set) var resetRevision = 0
    private(set) var recentActivityState: RecentActivityState = .idle
    private(set) var recentActivities: [RecentLearningActivity] = []
    private(set) var experienceAchievementState: ExperienceAchievementState = .idle
    private(set) var experienceAchievements: [AchievementProgress] = []

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

    var achievements: [AchievementProgress] {
        (snapshot?.achievements ?? []) + experienceAchievements
    }

    var earnedAchievementCount: Int {
        achievements.count(where: \.isEarned)
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
    private let loadRecentActivityUseCase: LoadRecentLearningActivityUseCase
    private let loadExperienceAchievementsUseCase: LoadExperienceAchievementsUseCase
    private let updateProfile: UpdateLearnerProfileUseCase
    private let resetLearningProgressUseCase: ResetLearningProgressUseCase

    init(
        loadProfile: LoadLearnerProfileUseCase,
        loadMasteryOverview: LoadMasteryOverviewUseCase,
        loadRecentActivity: LoadRecentLearningActivityUseCase,
        loadExperienceAchievements: LoadExperienceAchievementsUseCase,
        updateProfile: UpdateLearnerProfileUseCase,
        resetLearningProgress: ResetLearningProgressUseCase
    ) {
        self.loadProfile = loadProfile
        self.loadMasteryOverview = loadMasteryOverview
        loadRecentActivityUseCase = loadRecentActivity
        loadExperienceAchievementsUseCase = loadExperienceAchievements
        self.updateProfile = updateProfile
        resetLearningProgressUseCase = resetLearningProgress
    }

    func load() {
        loadState = .loading

        do {
            let snapshot = try loadProfile.execute()
            apply(snapshot)
            masteryOverview = try loadMasteryOverview.execute()
            loadState = .loaded
            loadRecentActivity()
            loadExperienceAchievements()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func loadRecentActivity() {
        recentActivityState = .loading

        do {
            recentActivities = try loadRecentActivityUseCase.execute()
            recentActivityState = .loaded
        } catch {
            recentActivities = []
            recentActivityState = .failed(error.localizedDescription)
        }
    }

    func loadExperienceAchievements() {
        experienceAchievementState = .loading

        do {
            experienceAchievements = try loadExperienceAchievementsUseCase.execute()
            experienceAchievementState = .loaded
        } catch {
            experienceAchievements = []
            experienceAchievementState = .failed(error.localizedDescription)
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

    func resetLearningProgress() {
        resetState = .resetting

        do {
            try resetLearningProgressUseCase.execute()
            let snapshot = try loadProfile.execute()
            apply(snapshot)
            masteryOverview = try loadMasteryOverview.execute()
            loadRecentActivity()
            loadExperienceAchievements()
            loadState = .loaded
            resetRevision += 1
            resetState = .reset
        } catch {
            resetState = .failed(error.localizedDescription)
        }
    }

    private func apply(_ snapshot: LearnerProfileSnapshot) {
        self.snapshot = snapshot
        draftDisplayName = snapshot.profile.displayName
        draftAvatar = snapshot.profile.avatar
        draftCustomAvatarImageData = snapshot.profile.customAvatarImageData
        draftAppearance = snapshot.profile.appearance
        draftMotionPreference = snapshot.profile.motionPreference
    }

    static func recentActivityKindLabel(
        for kind: RecentLearningActivityKind
    ) -> String {
        switch kind {
        case .lesson:
            "Lesson"
        case .review:
            "Review"
        case .bossChallenge:
            "Boss challenge"
        case .guidedProject:
            "Guided project"
        }
    }

    static func recentActivityOutcomeLabel(for outcome: AttemptOutcome) -> String {
        switch outcome {
        case .correct:
            "Correct"
        case .incorrect:
            "Needs review"
        }
    }
}
