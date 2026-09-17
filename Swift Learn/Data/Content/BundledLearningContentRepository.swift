//
//  BundledLearningContentRepository.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import Foundation

@MainActor
final class BundledLearningContentRepository: LearningContentRepository {
    private let loadData: () throws -> Data

    init(
        bundle: Bundle,
        resourceName: String = "swift-6.4-beta-foundations"
    ) {
        loadData = {
            guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
                throw LearningContentError.resourceNotFound(resourceName)
            }
            return try Data(contentsOf: url)
        }
    }

    init(data: Data) {
        loadData = { data }
    }

    func loadCatalog() throws -> LearningCatalog {
        try JSONDecoder().decode(
            LearningCatalogDTO.self,
            from: loadData()
        ).domainModel()
    }
}

enum LearningContentError: LocalizedError, Equatable {
    case resourceNotFound(String)
    case invalidActivityPayload(String)
    case unsupportedActivitySchema(Int)
    case unsupportedActivityType(String)

    var errorDescription: String? {
        switch self {
        case let .resourceNotFound(name):
            "Missing learning resource: \(name).json"
        case let .invalidActivityPayload(lessonID):
            "Lesson has an invalid activity payload: \(lessonID)."
        case let .unsupportedActivitySchema(version):
            "Unsupported learning activity schema version: \(version)."
        case let .unsupportedActivityType(type):
            "Unsupported learning activity type: \(type)."
        }
    }
}

private struct LearningCatalogDTO: Decodable {
    let sourceID: String
    let editionTitle: String
    let levels: [LearningLevelDTO]

    func domainModel() throws -> LearningCatalog {
        try LearningCatalog(
            sourceID: sourceID,
            editionTitle: editionTitle,
            levels: levels.map { try $0.domainModel() }
        )
    }
}

private struct LearningLevelDTO: Decodable {
    let id: String
    let title: String
    let summary: String
    let lessons: [LearningLessonDTO]

    func domainModel() throws -> LearningLevel {
        try LearningLevel(
            id: id,
            title: title,
            summary: summary,
            lessons: lessons.map { try $0.domainModel() }
        )
    }
}

private struct LearningLessonDTO: Decodable {
    let id: String
    let title: String
    let objective: String
    let instruction: String
    let activity: LearningActivityDTO?
    let codePrefix: String?
    let codeSuffix: String?
    let choices: [LearningChoiceDTO]?
    let correctChoiceID: String?
    let correctFeedback: String
    let incorrectFeedback: String
    let sourceTitle: String
    let sourceReferences: [String]

    func domainModel() throws -> LearningLesson {
        let domainActivity: LearningActivity
        if let activity {
            domainActivity = try activity.domainModel(lessonID: id)
        } else {
            guard let codePrefix,
                  let codeSuffix,
                  let choices,
                  let correctChoiceID else {
                throw LearningContentError.invalidActivityPayload(id)
            }
            let domainChoices = choices.map(\.domainModel)
            guard !domainChoices.isEmpty,
                  domainChoices.contains(where: { $0.id == correctChoiceID }) else {
                throw LearningContentError.invalidActivityPayload(id)
            }
            domainActivity = .missingCode(
                MissingCodeActivity(
                    schemaVersion: 1,
                    prompt: "Choose the missing Swift code",
                    codePrefix: codePrefix,
                    codeSuffix: codeSuffix,
                    choices: domainChoices,
                    correctChoiceID: correctChoiceID
                )
            )
        }

        return LearningLesson(
            id: id,
            title: title,
            objective: objective,
            instruction: instruction,
            activity: domainActivity,
            correctFeedback: correctFeedback,
            incorrectFeedback: incorrectFeedback,
            sourceTitle: sourceTitle,
            sourceReferences: sourceReferences
        )
    }
}

private struct LearningActivityDTO: Decodable {
    let schemaVersion: Int
    let type: String
    let prompt: String
    let code: String?
    let codePrefix: String?
    let codeSuffix: String?
    let faultyCode: String?
    let choices: [LearningChoiceDTO]?
    let correctChoiceID: String?
    let fragments: [LearningChoiceDTO]?
    let correctOrderIDs: [String]?
    let starterText: String?
    let acceptedSolutions: [String]?
    let maxLength: Int?
    let tokens: [LearningChoiceDTO]?
    let canonicalTokenIDs: [String]?

    func domainModel(lessonID: String) throws -> LearningActivity {
        guard schemaVersion == 1 else {
            throw LearningContentError.unsupportedActivitySchema(schemaVersion)
        }
        guard !prompt.isEmpty else {
            throw LearningContentError.invalidActivityPayload(lessonID)
        }

        switch type {
        case LearningActivityKind.missingCode.rawValue:
            guard let codePrefix, let codeSuffix,
                  let choices, let correctChoiceID,
                  !choices.isEmpty,
                  choices.contains(where: { $0.id == correctChoiceID }) else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .missingCode(
                MissingCodeActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    codePrefix: codePrefix,
                    codeSuffix: codeSuffix,
                    choices: choices.map(\.domainModel),
                    correctChoiceID: correctChoiceID
                )
            )
        case LearningActivityKind.outputPrediction.rawValue:
            guard let code, !code.isEmpty,
                  let choices, let correctChoiceID,
                  !choices.isEmpty,
                  choices.contains(where: { $0.id == correctChoiceID }) else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .outputPrediction(
                OutputPredictionActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    code: code,
                    choices: choices.map(\.domainModel),
                    correctChoiceID: correctChoiceID
                )
            )
        case LearningActivityKind.codeOrdering.rawValue:
            guard let fragments, let correctOrderIDs,
                  fragments.count >= 2,
                  fragments.allSatisfy({ !$0.id.isEmpty && !$0.code.isEmpty }),
                  Set(fragments.map(\.id)).count == fragments.count,
                  correctOrderIDs.count == fragments.count,
                  Set(correctOrderIDs) == Set(fragments.map(\.id)) else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .codeOrdering(
                CodeOrderingActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    fragments: fragments.map(\.domainModel),
                    correctOrderIDs: correctOrderIDs
                )
            )
        case LearningActivityKind.diagnosticSelection.rawValue:
            guard let code, !code.isEmpty,
                  let choices, let correctChoiceID,
                  choices.count >= 2,
                  choices.allSatisfy({ !$0.id.isEmpty && !$0.code.isEmpty }),
                  Set(choices.map(\.id)).count == choices.count,
                  choices.contains(where: { $0.id == correctChoiceID }) else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .diagnosticSelection(
                DiagnosticSelectionActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    code: code,
                    choices: choices.map(\.domainModel),
                    correctChoiceID: correctChoiceID
                )
            )
        case LearningActivityKind.codeRepair.rawValue:
            guard let codePrefix, let faultyCode, let codeSuffix,
                  !faultyCode.isEmpty,
                  let choices, let correctChoiceID,
                  choices.count >= 2,
                  choices.allSatisfy({ !$0.id.isEmpty && !$0.code.isEmpty }),
                  Set(choices.map(\.id)).count == choices.count,
                  choices.contains(where: { $0.id == correctChoiceID }) else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .codeRepair(
                CodeRepairActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    codePrefix: codePrefix,
                    faultyCode: faultyCode,
                    codeSuffix: codeSuffix,
                    choices: choices.map(\.domainModel),
                    correctChoiceID: correctChoiceID
                )
            )
        case LearningActivityKind.constrainedEditing.rawValue:
            guard let codePrefix, let codeSuffix,
                  let starterText, let acceptedSolutions,
                  let maxLength, let tokens, let canonicalTokenIDs,
                  maxLength > 0, maxLength <= 200,
                  starterText.count <= maxLength,
                  acceptedSolutions.isEmpty == false,
                  acceptedSolutions.allSatisfy({
                      !$0.isEmpty && $0.count <= maxLength && !$0.contains("\n")
                  }),
                  tokens.count >= 2,
                  tokens.allSatisfy({ !$0.id.isEmpty && !$0.code.isEmpty }),
                  Set(tokens.map(\.id)).count == tokens.count,
                  canonicalTokenIDs.count == tokens.count,
                  Set(canonicalTokenIDs) == Set(tokens.map(\.id)),
                  acceptedSolutions.contains(
                      canonicalTokenIDs.compactMap { id in
                          tokens.first { $0.id == id }?.code
                      }.joined()
                  ) else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .constrainedEditing(
                ConstrainedEditingActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    codePrefix: codePrefix,
                    codeSuffix: codeSuffix,
                    starterText: starterText,
                    acceptedSolutions: acceptedSolutions,
                    maxLength: maxLength,
                    tokens: tokens.map(\.domainModel),
                    canonicalTokenIDs: canonicalTokenIDs
                )
            )
        default:
            throw LearningContentError.unsupportedActivityType(type)
        }
    }
}

private struct LearningChoiceDTO: Decodable {
    let id: String
    let code: String

    var domainModel: LearningChoice {
        LearningChoice(id: id, code: code)
    }
}
