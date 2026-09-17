//
//  AuthoredActivities.swift
//  Swift Learn
//

struct UnitTestAuthoringActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let framework: String
    let target: String
    let requiredAssertion: String
    let expectedOutcome: String
    let composition: ConstrainedEditingActivity
}

struct UITestAuthoringActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let framework: String
    let entryIdentifier: String
    let resultIdentifier: String
    let expectedOutcome: String
    let composition: ConstrainedEditingActivity
}

enum ArchitectureLayer: String, CaseIterable, Equatable, Hashable, Sendable {
    case app
    case presentation
    case domain
    case data
}

struct ArchitectureBoundaryItem: Identifiable, Equatable, Sendable {
    let id: String
    let responsibility: String
    let correctLayer: ArchitectureLayer
}

struct ArchitectureClassificationActivity: Equatable, Sendable {
    let schemaVersion: Int
    let prompt: String
    let items: [ArchitectureBoundaryItem]
}
