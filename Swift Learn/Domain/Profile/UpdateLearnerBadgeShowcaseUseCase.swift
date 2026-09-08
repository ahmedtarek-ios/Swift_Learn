//
//  UpdateLearnerBadgeShowcaseUseCase.swift
//  Swift Learn
//
//  Created by Codex on 08/09/2026.
//

@MainActor
struct UpdateLearnerBadgeShowcaseUseCase {
    private let profileRepository: any LearnerProfileRepository

    init(profileRepository: any LearnerProfileRepository) {
        self.profileRepository = profileRepository
    }

    func execute(
        achievementID: String?,
        achievements: [AchievementProgress]
    ) throws -> LearnerProfile {
        if let achievementID,
           achievements.contains(where: {
               $0.id == achievementID && $0.isEarned
           }) == false {
            throw LearnerProfileError.achievementNotEarned
        }

        return try save(achievementID: achievementID)
    }

    func reconcile(
        achievements: [AchievementProgress]
    ) throws -> LearnerProfile {
        let profile = try profileRepository.loadProfile()
        guard let achievementID = profile.showcasedAchievementID else {
            return profile
        }
        guard achievements.contains(where: {
            $0.id == achievementID && $0.isEarned
        }) == false else {
            return profile
        }

        return try save(profile: profile, achievementID: nil)
    }

    private func save(achievementID: String?) throws -> LearnerProfile {
        try save(
            profile: profileRepository.loadProfile(),
            achievementID: achievementID
        )
    }

    private func save(
        profile: LearnerProfile,
        achievementID: String?
    ) throws -> LearnerProfile {
        let updatedProfile = LearnerProfile(
            displayName: profile.displayName,
            avatar: profile.avatar,
            customAvatarImageData: profile.customAvatarImageData,
            appearance: profile.appearance,
            motionPreference: profile.motionPreference,
            showcasedAchievementID: achievementID
        )
        try profileRepository.saveProfile(updatedProfile)
        return updatedProfile
    }
}
