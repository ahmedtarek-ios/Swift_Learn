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

        let profile = LearnerProfile(
            displayName: normalizedName,
            avatar: avatar,
            appearance: appearance,
            motionPreference: motionPreference
        )
        try profileRepository.saveProfile(profile)
        return profile
    }
}
