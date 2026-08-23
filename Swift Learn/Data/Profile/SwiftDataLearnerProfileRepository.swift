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

        return LearnerProfile(
            displayName: record.displayName,
            avatar: LearnerAvatar(rawValue: record.avatarRawValue) ?? .code,
            appearance: LearnerAppearance(rawValue: record.appearanceRawValue) ?? .system,
            motionPreference: LearnerMotionPreference(
                rawValue: record.motionPreferenceRawValue
            ) ?? .system
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

        try modelContext.save()
    }

    private func profileRecord() throws -> LearnerProfileRecord? {
        try modelContext.fetch(FetchDescriptor<LearnerProfileRecord>()).first {
            $0.profileID == "local-learner"
        }
    }
}
