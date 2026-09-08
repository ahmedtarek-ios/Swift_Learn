//
//  LearnerBadgeShowcaseRecord.swift
//  Swift Learn
//
//  Created by Codex on 08/09/2026.
//

import SwiftData

@Model
final class LearnerBadgeShowcaseRecord {
    @Attribute(.unique) var profileID: String
    var achievementID: String

    init(
        profileID: String = "local-learner",
        achievementID: String
    ) {
        self.profileID = profileID
        self.achievementID = achievementID
    }
}
