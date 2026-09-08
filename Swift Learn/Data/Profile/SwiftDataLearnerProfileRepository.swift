//
//  SwiftDataLearnerProfileRepository.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftData

@MainActor
final class SwiftDataLearnerProfileRepository: LearnerProfileRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadProfile() throws -> LearnerProfile {
        guard let record = try profileRecord() else {
            return .defaultProfile
        }

        let avatar = LearnerAvatar(rawValue: record.avatarRawValue) ?? .unknown
        return LearnerProfile(
            displayName: record.displayName,
            avatar: avatar,
            customAvatarImageData: avatar == .custom
                ? try avatarImageRecord()?.imageData
                : nil,
            appearance: LearnerAppearance(rawValue: record.appearanceRawValue) ?? .system,
            motionPreference: LearnerMotionPreference(
                rawValue: record.motionPreferenceRawValue
            ) ?? .system,
            showcasedAchievementID: try badgeShowcaseRecord()?.achievementID
        )
    }

    func saveProfile(_ profile: LearnerProfile) throws {
        if let record = try profileRecord() {
            record.displayName = profile.displayName
            record.avatarRawValue = profile.avatar.rawValue
            record.appearanceRawValue = profile.appearance.rawValue
            record.motionPreferenceRawValue = profile.motionPreference.rawValue
        } else {
            modelContext.insert(
                LearnerProfileRecord(
                    displayName: profile.displayName,
                    avatarRawValue: profile.avatar.rawValue,
                    appearanceRawValue: profile.appearance.rawValue,
                    motionPreferenceRawValue: profile.motionPreference.rawValue
                )
            )
        }

        if let achievementID = profile.showcasedAchievementID {
            if let showcaseRecord = try badgeShowcaseRecord() {
                showcaseRecord.achievementID = achievementID
            } else {
                modelContext.insert(
                    LearnerBadgeShowcaseRecord(achievementID: achievementID)
                )
            }
        } else if let showcaseRecord = try badgeShowcaseRecord() {
            modelContext.delete(showcaseRecord)
        }

        if profile.avatar == .custom,
           let imageData = profile.customAvatarImageData,
           imageData.isEmpty == false {
            if let imageRecord = try avatarImageRecord() {
                imageRecord.imageData = imageData
            } else {
                modelContext.insert(LearnerAvatarImageRecord(imageData: imageData))
            }
        } else if let imageRecord = try avatarImageRecord() {
            modelContext.delete(imageRecord)
        }

        try modelContext.save()
    }

    private func profileRecord() throws -> LearnerProfileRecord? {
        try modelContext.fetch(FetchDescriptor<LearnerProfileRecord>()).first {
            $0.profileID == "local-learner"
        }
    }


    private func avatarImageRecord() throws -> LearnerAvatarImageRecord? {
        try modelContext.fetch(FetchDescriptor<LearnerAvatarImageRecord>()).first {
            $0.profileID == "local-learner"
        }
    }

    private func badgeShowcaseRecord() throws -> LearnerBadgeShowcaseRecord? {
        try modelContext.fetch(
            FetchDescriptor<LearnerBadgeShowcaseRecord>()
        ).first {
            $0.profileID == "local-learner"
        }
    }
}
