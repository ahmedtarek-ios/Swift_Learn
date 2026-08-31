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
    let choices: [LearningChoiceDTO]
    let correctChoiceID: String

    func domainModel(lessonID: String) throws -> LearningActivity {
        guard schemaVersion == 1 else {
            throw LearningContentError.unsupportedActivitySchema(schemaVersion)
        }
        let domainChoices = choices.map(\.domainModel)
        guard !prompt.isEmpty,
              !domainChoices.isEmpty,
              domainChoices.contains(where: { $0.id == correctChoiceID }) else {
            throw LearningContentError.invalidActivityPayload(lessonID)
        }

        switch type {
        case LearningActivityKind.missingCode.rawValue:
            guard let codePrefix, let codeSuffix else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .missingCode(
                MissingCodeActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    codePrefix: codePrefix,
                    codeSuffix: codeSuffix,
                    choices: domainChoices,
                    correctChoiceID: correctChoiceID
                )
            )
        case LearningActivityKind.outputPrediction.rawValue:
            guard let code, !code.isEmpty else {
                throw LearningContentError.invalidActivityPayload(lessonID)
            }
            return .outputPrediction(
                OutputPredictionActivity(
                    schemaVersion: schemaVersion,
                    prompt: prompt,
                    code: code,
                    choices: domainChoices,
                    correctChoiceID: correctChoiceID
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
