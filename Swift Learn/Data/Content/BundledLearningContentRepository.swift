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
        try JSONDecoder().decode(LearningCatalogDTO.self, from: loadData()).domainModel
    }
}

enum LearningContentError: LocalizedError, Equatable {
    case resourceNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .resourceNotFound(name):
            "Missing learning resource: \(name).json"
        }
    }
}

private struct LearningCatalogDTO: Decodable {
    let sourceID: String
    let editionTitle: String
    let levels: [LearningLevelDTO]

    var domainModel: LearningCatalog {
        LearningCatalog(
            sourceID: sourceID,
            editionTitle: editionTitle,
            levels: levels.map(\.domainModel)
        )
    }
}

private struct LearningLevelDTO: Decodable {
    let id: String
    let title: String
    let summary: String
    let lessons: [LearningLessonDTO]

    var domainModel: LearningLevel {
        LearningLevel(
            id: id,
            title: title,
            summary: summary,
            lessons: lessons.map(\.domainModel)
        )
    }
}

private struct LearningLessonDTO: Decodable {
    let id: String
    let title: String
    let objective: String
    let instruction: String
    let codePrefix: String
    let codeSuffix: String
    let choices: [LearningChoiceDTO]
    let correctChoiceID: String
    let correctFeedback: String
    let incorrectFeedback: String
    let sourceTitle: String
    let sourceReferences: [String]

    var domainModel: LearningLesson {
        LearningLesson(
            id: id,
            title: title,
            objective: objective,
            instruction: instruction,
            codePrefix: codePrefix,
            codeSuffix: codeSuffix,
            choices: choices.map(\.domainModel),
            correctChoiceID: correctChoiceID,
            correctFeedback: correctFeedback,
            incorrectFeedback: incorrectFeedback,
            sourceTitle: sourceTitle,
            sourceReferences: sourceReferences
        )
    }
}

private struct LearningChoiceDTO: Decodable {
    let id: String
    let code: String

    var domainModel: LearningChoice {
        LearningChoice(id: id, code: code)
    }
}
