//
//  LearnerAvatarImageRecord.swift
//  Swift Learn
//
//  Created by Codex on 30/08/2026.
//

import Foundation
import SwiftData

@Model
final class LearnerAvatarImageRecord {
    @Attribute(.unique) var profileID: String
    @Attribute(.externalStorage) var imageData: Data

    init(
        profileID: String = "local-learner",
        imageData: Data
    ) {
        self.profileID = profileID
        self.imageData = imageData
    }
}
