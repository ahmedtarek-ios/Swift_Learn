//
//  UpdateLearnerProfileUseCase.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation

@MainActor
struct UpdateLearnerProfileUseCase {
    private let profileRepository: any LearnerProfileRepository

    init(profileRepository: any LearnerProfileRepository) {
        self.profileRepository = profileRepository
    }

    func execute(
        displayName: String,
        avatar: LearnerAvatar,
        customAvatarImageData: Data? = nil,
        appearance: LearnerAppearance,
        motionPreference: LearnerMotionPreference = .system
    ) throws -> LearnerProfile {
        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            throw LearnerProfileError.emptyDisplayName
        }
        guard normalizedName.count <= 40 else {
            throw LearnerProfileError.displayNameTooLong
        }
        if avatar == .custom,
           customAvatarImageData?.isEmpty != false {
            throw LearnerProfileError.missingCustomAvatarImage
        }

        let profile = LearnerProfile(
            displayName: normalizedName,
            avatar: avatar,
            customAvatarImageData: avatar == .custom ? customAvatarImageData : nil,
            appearance: appearance,
            motionPreference: motionPreference
        )
        try profileRepository.saveProfile(profile)
        return profile
    }
}
