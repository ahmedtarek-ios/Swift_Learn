//
//  LearningProjectSubmissionRecord.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation
import SwiftData

@Model
final class LearningProjectSubmissionRecord {
    @Attribute(.unique) var id: UUID
    var projectID: String
    var validationResultsData: Data
    var submittedAt: Date

    init(
        id: UUID,
        projectID: String,
        validationResultsData: Data,
        submittedAt: Date
    ) {
        self.id = id
        self.projectID = projectID
        self.validationResultsData = validationResultsData
        self.submittedAt = submittedAt
    }
}
