import Foundation

@MainActor
final class BundledGitCommandRepository: GitCommandContentRepository {
    private let loadData: () throws -> Data
    private var cached: GitCommandCatalog?

    init(bundle: Bundle, resourceName: String = "git-commands-foundations") {
        loadData = {
            guard let url = bundle.url(forResource: resourceName, withExtension: "json")
            else {
                throw GitContentError.resourceNotFound(resourceName)
            }
            return try Data(contentsOf: url)
        }
    }

    init(data: Data) {
        loadData = { data }
    }

    func loadCatalog() throws -> GitCommandCatalog {
        if let cached { return cached }
        let catalog = try JSONDecoder()
            .decode(GitCommandCatalogDTO.self, from: loadData())
            .domainModel()
        cached = catalog
        return catalog
    }
}

enum GitContentError: LocalizedError, Equatable {
    case resourceNotFound(String)
    case unsupportedSchema(Int)
    case unsupportedSafetyLevel(String)

    var errorDescription: String? {
        switch self {
        case let .resourceNotFound(name):
            "Missing Git resource: \(name).json"
        case let .unsupportedSchema(version):
            "Unsupported Git catalog schema: \(version)."
        case let .unsupportedSafetyLevel(value):
            "Unsupported Git safety level: \(value)."
        }
    }
}

// MARK: - DTOs

struct GitCommandCatalogDTO: Decodable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let sourceID: String
    let editionTitle: String
    let categories: [GitCommandCategoryDTO]

    func domainModel() throws -> GitCommandCatalog {
        guard schemaVersion == Self.supportedSchemaVersion else {
            throw GitContentError.unsupportedSchema(schemaVersion)
        }
        return GitCommandCatalog(
            sourceID: sourceID,
            editionTitle: editionTitle,
            categories: try categories.map { try $0.domainModel() }
        )
    }
}

struct GitCommandCategoryDTO: Decodable {
    let id: String
    let title: String
    let summary: String
    let lessons: [GitCommandLessonDTO]

    func domainModel() throws -> GitCommandCategory {
        GitCommandCategory(
            id: id,
            title: title,
            summary: summary,
            lessons: try lessons.map { try $0.domainModel(categoryID: id) }
        )
    }
}

struct GitCommandLessonDTO: Decodable {
    let id: String
    let title: String
    let objective: String
    let scenario: String
    let prompt: String
    let choices: [GitCommandChoiceDTO]
    let correctChoiceID: String
    let correctFeedback: String
    let incorrectFeedback: String
    let sourceReferences: [String]
    let safetyLevel: String
    let safetyWarning: String?

    func domainModel(categoryID: String) throws -> GitCommandLesson {
        guard let level = GitCommandSafetyLevel(rawValue: safetyLevel) else {
            throw GitContentError.unsupportedSafetyLevel(safetyLevel)
        }
        return GitCommandLesson(
            id: id,
            title: title,
            objective: objective,
            scenario: scenario,
            prompt: prompt,
            choices: choices.map { GitCommandChoice(id: $0.id, command: $0.command) },
            correctChoiceID: correctChoiceID,
            correctFeedback: correctFeedback,
            incorrectFeedback: incorrectFeedback,
            categoryID: categoryID,
            sourceReferences: sourceReferences,
            safetyLevel: level,
            safetyWarning: safetyWarning
        )
    }
}

struct GitCommandChoiceDTO: Decodable {
    let id: String
    let command: String
}
