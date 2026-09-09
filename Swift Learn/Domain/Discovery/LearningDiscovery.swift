import Foundation

enum LearningDiscoveryMatchField: String, CaseIterable, Equatable, Sendable {
    case skill
    case syntax
    case diagnostic
    case source
}

struct LearningDiscoveryItem: Identifiable, Equatable, Sendable {
    var id: SkillID { skill.id }

    let skill: CanonicalSkill
    let levelID: String
    let levelTitle: String
    let lessons: [LearningLesson]

    var primaryLesson: LearningLesson? {
        lessons.first
    }
}

struct LearningDiscoveryResult: Identifiable, Equatable, Sendable {
    var id: SkillID { item.id }

    let item: LearningDiscoveryItem
    let matchedFields: Set<LearningDiscoveryMatchField>
}

struct LearningDiscoverySnapshot: Equatable, Sendable {
    let sourceID: String
    let editionTitle: String
    let items: [LearningDiscoveryItem]
}

enum LearningDiscoveryError: LocalizedError, Equatable {
    case skillWithoutLesson(String)

    var errorDescription: String? {
        switch self {
        case let .skillWithoutLesson(id):
            "Canonical skill has no catalog lesson: \(id)."
        }
    }
}

@MainActor
struct LoadLearningDiscoveryUseCase {
    private let contentRepository: any LearningContentRepository
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase

    init(
        contentRepository: any LearningContentRepository,
        loadCanonicalSkills: LoadCanonicalSkillsUseCase
    ) {
        self.contentRepository = contentRepository
        self.loadCanonicalSkills = loadCanonicalSkills
    }

    func execute() throws -> LearningDiscoverySnapshot {
        let catalog = try contentRepository.loadCatalog()
        let skills = try loadCanonicalSkills.execute()
        let lessonOrder = Dictionary(
            uniqueKeysWithValues: catalog.lessons.enumerated().map { ($0.element.id, $0.offset) }
        )
        let levelByLessonID = Dictionary(
            uniqueKeysWithValues: catalog.levels.flatMap { level in
                level.lessons.map { ($0.id, level) }
            }
        )

        let items = try skills.map { skill -> LearningDiscoveryItem in
            let lessons = skill.lessonIDs.compactMap { catalog.lesson(id: $0) }.sorted {
                lessonOrder[$0.id, default: .max] < lessonOrder[$1.id, default: .max]
            }
            guard let firstLesson = lessons.first,
                  let level = levelByLessonID[firstLesson.id] else {
                throw LearningDiscoveryError.skillWithoutLesson(skill.id.rawValue)
            }
            return LearningDiscoveryItem(
                skill: skill,
                levelID: level.id,
                levelTitle: level.title,
                lessons: lessons
            )
        }.sorted {
            let left = $0.primaryLesson.flatMap { lessonOrder[$0.id] } ?? .max
            let right = $1.primaryLesson.flatMap { lessonOrder[$0.id] } ?? .max
            return left < right
        }

        return LearningDiscoverySnapshot(
            sourceID: catalog.sourceID,
            editionTitle: catalog.editionTitle,
            items: items
        )
    }
}

struct SearchLearningDiscoveryUseCase {
    func execute(
        query: String,
        snapshot: LearningDiscoverySnapshot
    ) -> [LearningDiscoveryResult] {
        let tokens = query
            .split(whereSeparator: \.isWhitespace)
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return [] }

        return snapshot.items.compactMap { item in
            let fields = searchableFields(for: item)
            let allText = fields.values.flatMap { $0 }.joined(separator: " ")
            guard tokens.allSatisfy(allText.contains) else { return nil }

            let matchedFields = Set(fields.compactMap { field, values in
                let fieldText = values.joined(separator: " ")
                return tokens.contains(where: fieldText.contains) ? field : nil
            })
            return LearningDiscoveryResult(item: item, matchedFields: matchedFields)
        }
    }

    private func searchableFields(
        for item: LearningDiscoveryItem
    ) -> [LearningDiscoveryMatchField: [String]] {
        let skillValues = [item.skill.title, item.levelTitle] + item.lessons.flatMap {
            [$0.title, $0.objective]
        }
        let syntaxValues = item.lessons.flatMap { lesson in
            [lesson.instruction, lesson.activity.code(selectedChoiceID: nil)]
                + lesson.choices.map(\.code)
        }
        let diagnosticValues = item.lessons.flatMap {
            [$0.activity.prompt, $0.correctFeedback, $0.incorrectFeedback]
        }
        let sourceValues = item.lessons.flatMap {
            [$0.sourceTitle] + $0.sourceReferences
        }

        return [
            .skill: skillValues.map(normalize),
            .syntax: syntaxValues.map(normalize),
            .diagnostic: diagnosticValues.map(normalize),
            .source: sourceValues.map(normalize)
        ]
    }

    private func normalize(_ value: String) -> String {
        value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
}
