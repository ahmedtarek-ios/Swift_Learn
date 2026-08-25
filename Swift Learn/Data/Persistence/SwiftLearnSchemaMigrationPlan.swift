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

enum SwiftLearnSchemaMigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        SwiftLearnSchemaV1.self,
        SwiftLearnSchemaV2.self
    ]

    static let stages: [MigrationStage] = [
        .lightweight(
            fromVersion: SwiftLearnSchemaV1.self,
            toVersion: SwiftLearnSchemaV2.self
        )
    ]
}
