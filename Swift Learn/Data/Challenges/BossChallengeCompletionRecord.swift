//
//  BossChallengeCompletionRecord.swift
//  Swift Learn
//
//  Created by Codex on 07/09/2026.
//

import Foundation
import SwiftData

@Model
final class BossChallengeCompletionRecord {
    @Attribute(.unique) var challengeID: String
    var levelID: String
    var completedAt: Date

    init(challengeID: String, levelID: String, completedAt: Date) {
        self.challengeID = challengeID
        self.levelID = levelID
        self.completedAt = completedAt
    }
}
