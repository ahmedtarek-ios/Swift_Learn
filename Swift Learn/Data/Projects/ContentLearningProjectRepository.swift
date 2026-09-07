//
//  ContentLearningProjectRepository.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import Foundation

@MainActor
final class ContentLearningProjectRepository: LearningProjectRepository {
    static let foundationsProjectID = "swift-foundations"

    private let contentRepository: any LearningContentRepository

    init(contentRepository: any LearningContentRepository) {
        self.contentRepository = contentRepository
    }

    func loadProjects() throws -> [LearningProject] {
        let catalog = try contentRepository.loadCatalog()
        let lessonIDs = [
            "swift.bindings.constants",
            "swift.bindings.type-annotations",
            "swift.bindings.identifier-naming"
        ]
        let lessons = try lessonIDs.map { lessonID in
            guard let lesson = catalog.lesson(id: lessonID) else {
                throw LearningProjectDataError.missingLesson(lessonID)
            }
            return lesson
        }

        return [
            LearningProject(
                id: Self.foundationsProjectID,
                title: "Build a Practice Setup",
                summary: "Apply constants, type annotations, and valid Swift names in one guided project.",
                requirements: lessons.enumerated().map { index, lesson in
                    LearningProjectRequirement(
                        id: "requirement.\(lesson.id)",
                        title: "Requirement \(index + 1): \(lesson.title)",
                        instruction: lesson.instruction,
                        lesson: lesson,
                        skillID: SkillID(rawValue: lesson.id)
                    )
                }
            )
        ]
    }
}

enum LearningProjectDataError: LocalizedError, Equatable {
    case missingLesson(String)
    case invalidStoredValidationResults

    var errorDescription: String? {
        switch self {
        case let .missingLesson(id):
            "Project content is missing lesson: \(id)."
        case .invalidStoredValidationResults:
            "Stored project validation results are invalid."
        }
    }
}
