//
//  LearnerProfileRecord.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftData

@Model
final class LearnerProfileRecord {
    @Attribute(.unique) var profileID: String
    var displayName: String
    var avatarRawValue: String
    var appearanceRawValue: String
    var motionPreferenceRawValue: String = LearnerMotionPreference.system.rawValue

    init(
        profileID: String = "local-learner",
        displayName: String,
        avatarRawValue: String,
        appearanceRawValue: String,
        motionPreferenceRawValue: String = LearnerMotionPreference.system.rawValue
    ) {
        self.profileID = profileID
        self.displayName = displayName
        self.avatarRawValue = avatarRawValue
        self.appearanceRawValue = appearanceRawValue
        self.motionPreferenceRawValue = motionPreferenceRawValue
    }
}
