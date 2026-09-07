//
//  SwiftLearnSchemaMigrationPlan.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import SwiftData

enum SwiftLearnSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [
        LessonProgressRecord.self,
        LearnerProfileRecord.self
    ]
}

enum SwiftLearnSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static let models: [any PersistentModel.Type] = [
        LessonProgressRecord.self,
        LearnerProfileRecord.self,
        LearningAttemptRecord.self
    ]
}

enum SwiftLearnSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static let models: [any PersistentModel.Type] = [
        LessonProgressRecord.self,
        LearnerProfileRecord.self,
        LearningAttemptRecord.self,
        LearnerAvatarImageRecord.self
    ]
}

enum SwiftLearnSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)
    static let models: [any PersistentModel.Type] = [
        LessonProgressRecord.self,
        LearnerProfileRecord.self,
        LearningAttemptRecord.self,
        LearnerAvatarImageRecord.self,
        LearningProjectSubmissionRecord.self
    ]
}

enum SwiftLearnSchemaV5: VersionedSchema {
    static let versionIdentifier = Schema.Version(5, 0, 0)
    static let models: [any PersistentModel.Type] = [
        LessonProgressRecord.self,
        LearnerProfileRecord.self,
        LearningAttemptRecord.self,
        LearnerAvatarImageRecord.self,
        LearningProjectSubmissionRecord.self,
        BossChallengeCompletionRecord.self
    ]
}

enum SwiftLearnSchemaMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        SwiftLearnSchemaV1.self,
        SwiftLearnSchemaV2.self,
        SwiftLearnSchemaV3.self,
        SwiftLearnSchemaV4.self,
        SwiftLearnSchemaV5.self
    ]

    static let stages: [MigrationStage] = [
        .lightweight(
            fromVersion: SwiftLearnSchemaV1.self,
            toVersion: SwiftLearnSchemaV2.self
        ),
        .lightweight(
            fromVersion: SwiftLearnSchemaV2.self,
            toVersion: SwiftLearnSchemaV3.self
        ),
        .lightweight(
            fromVersion: SwiftLearnSchemaV3.self,
            toVersion: SwiftLearnSchemaV4.self
        ),
        .lightweight(
            fromVersion: SwiftLearnSchemaV4.self,
            toVersion: SwiftLearnSchemaV5.self
        )
    ]
}
