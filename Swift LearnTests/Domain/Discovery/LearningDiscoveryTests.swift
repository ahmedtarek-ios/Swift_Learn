import Foundation
import Testing
@testable import Swift_Learn

@MainActor
struct LearningDiscoveryTests {
    @Test
    func journeyDerivesResumeLevelProgressAndExactLockReason() throws {
        let catalog = makeCatalog()
        let journey = LearningJourney(
            catalog: catalog,
            completedLessonIDs: ["lesson.constants"]
        )
        let level = try #require(catalog.levels.first)

        #expect(journey.resumeLesson?.id == "lesson.variables")
        #expect(journey.progress(for: level).completedLessonCount == 1)
        #expect(journey.progress(for: level).totalLessonCount == 3)
        #expect(
            journey.availability(for: "lesson.types")
                == .locked(
                    prerequisiteLessonID: "lesson.variables",
                    prerequisiteTitle: "Variables"
                )
        )
    }

    @Test
    func discoveryReusesCanonicalSkillIdentityAndCatalogOrder() throws {
        let catalog = makeCatalog()
        let content = DiscoveryContentRepository(catalog: catalog)
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: DiscoverySkillRepository(skills: makeSkills())
        )

        let snapshot = try LoadLearningDiscoveryUseCase(
            contentRepository: content,
            loadCanonicalSkills: loadSkills
        ).execute()

        #expect(snapshot.items.map(\.id.rawValue) == catalog.lessons.map(\.id))
        #expect(Set(snapshot.items.map(\.id)).count == snapshot.items.count)
        #expect(snapshot.sourceID == catalog.sourceID)
    }

    @Test(
        arguments: [
            ("let", LearningDiscoveryMatchField.syntax),
            ("cannot change", LearningDiscoveryMatchField.diagnostic),
            ("guide#constants", LearningDiscoveryMatchField.source)
        ]
    )
    func searchFindsSkillBySupportedField(
        query: String,
        field: LearningDiscoveryMatchField
    ) throws {
        let snapshot = try makeDiscoverySnapshot()

        let results = SearchLearningDiscoveryUseCase().execute(
            query: query,
            snapshot: snapshot
        )

        let result = try #require(results.first)
        #expect(result.item.id.rawValue == "lesson.constants")
        #expect(result.matchedFields.contains(field))
    }

    @Test
    func emptySearchReturnsNoDuplicateGlossaryResults() throws {
        let snapshot = try makeDiscoverySnapshot()
        let results = SearchLearningDiscoveryUseCase().execute(
            query: "   ",
            snapshot: snapshot
        )

        #expect(results.isEmpty)
        #expect(Set(snapshot.items.map(\.id)).count == snapshot.items.count)
    }

    @Test
    func discoveryViewModelOwnsLoadingAndSearchState() throws {
        let catalog = makeCatalog()
        let content = DiscoveryContentRepository(catalog: catalog)
        let viewModel = LearningDiscoveryViewModel(
            loadDiscovery: LoadLearningDiscoveryUseCase(
                contentRepository: content,
                loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                    contentRepository: content,
                    skillRepository: DiscoverySkillRepository(skills: makeSkills())
                )
            ),
            searchDiscovery: SearchLearningDiscoveryUseCase()
        )

        viewModel.load()
        viewModel.query = "answer = 42"

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.searchResults.map(\.id.rawValue) == ["lesson.constants"])
    }

    @Test
    func discoveryRejectsCanonicalSkillWithoutCatalogLesson() {
        let catalog = LearningCatalog(
            sourceID: "fixture.swift",
            editionTitle: "Fixture Swift",
            levels: []
        )
        let content = DiscoveryContentRepository(catalog: catalog)
        let orphanID = SkillID(rawValue: "skill.orphan")
        let loadSkills = LoadCanonicalSkillsUseCase(
            contentRepository: content,
            skillRepository: DiscoverySkillRepository(
                skills: [
                    CanonicalSkill(
                        id: orphanID,
                        title: "Orphan",
                        lessonIDs: [],
                        activityIDs: []
                    )
                ]
            )
        )

        #expect(throws: LearningDiscoveryError.skillWithoutLesson(orphanID.rawValue)) {
            try LoadLearningDiscoveryUseCase(
                contentRepository: content,
                loadCanonicalSkills: loadSkills
            ).execute()
        }
    }

    @Test
    func dataReportExportsOnlyLearningTotals() {
        let catalog = makeCatalog()
        let snapshot = LearnerProfileSnapshot(
            profile: .defaultProfile,
            journey: LearningJourney(
                catalog: catalog,
                completedLessonIDs: ["lesson.constants"]
            ),
            achievements: []
        )
        let achievement = AchievementProgress(
            definition: AchievementDefinition(
                id: "first",
                title: "First",
                summary: "First lesson",
                kind: .firstLesson
            ),
            completedRequirementCount: 1,
            totalRequirementCount: 1
        )

        let report = CreateLearnerDataReportUseCase().execute(
            snapshot: snapshot,
            mastery: MasteryOverview(snapshots: []),
            recentActivities: [],
            achievements: [achievement]
        )

        #expect(report.completedLessonCount == 1)
        #expect(report.totalLessonCount == 3)
        #expect(report.earnedAchievementCount == 1)
        #expect(report.exportText.contains("Source: fixture.swift"))
        #expect(report.exportText.contains("avatar") == false)
    }

    private func makeDiscoverySnapshot() throws -> LearningDiscoverySnapshot {
        let catalog = makeCatalog()
        let content = DiscoveryContentRepository(catalog: catalog)
        return try LoadLearningDiscoveryUseCase(
            contentRepository: content,
            loadCanonicalSkills: LoadCanonicalSkillsUseCase(
                contentRepository: content,
                skillRepository: DiscoverySkillRepository(skills: makeSkills())
            )
        ).execute()
    }

    private func makeCatalog() -> LearningCatalog {
        let lessons = [
            makeLesson(
                id: "lesson.constants",
                title: "Constants",
                objective: "Store an immutable value.",
                instruction: "Choose let for a value that cannot change.",
                code: "let answer = 42",
                feedback: "A constant cannot change.",
                source: "guide#constants"
            ),
            makeLesson(
                id: "lesson.variables",
                title: "Variables",
                objective: "Store a mutable value.",
                instruction: "Choose var for a changing value.",
                code: "var score = 0",
                feedback: "A variable can change.",
                source: "guide#variables"
            ),
            makeLesson(
                id: "lesson.types",
                title: "Type Annotations",
                objective: "Declare a value type.",
                instruction: "Add an explicit String type.",
                code: "let name: String = \"Swift\"",
                feedback: "The annotation names the type.",
                source: "guide#types"
            )
        ]
        return LearningCatalog(
            sourceID: "fixture.swift",
            editionTitle: "Fixture Swift",
            levels: [
                LearningLevel(
                    id: "level.foundation",
                    title: "Foundations",
                    summary: "Core declarations",
                    lessons: lessons
                )
            ]
        )
    }

    private func makeLesson(
        id: String,
        title: String,
        objective: String,
        instruction: String,
        code: String,
        feedback: String,
        source: String
    ) -> LearningLesson {
        LearningLesson(
            id: id,
            title: title,
            objective: objective,
            instruction: instruction,
            activity: .outputPrediction(
                OutputPredictionActivity(
                    schemaVersion: 1,
                    prompt: "What does this declaration do?",
                    code: code,
                    choices: [LearningChoice(id: "answer", code: "Answer")],
                    correctChoiceID: "answer"
                )
            ),
            correctFeedback: feedback,
            incorrectFeedback: feedback,
            sourceTitle: "Fixture Source",
            sourceReferences: [source]
        )
    }

    private func makeSkills() -> [CanonicalSkill] {
        ["lesson.constants", "lesson.variables", "lesson.types"].map { id in
            CanonicalSkill(
                id: SkillID(rawValue: id),
                title: id.split(separator: ".").last.map(String.init) ?? id,
                lessonIDs: [id],
                activityIDs: [
                    LearningActivityID(rawValue: id),
                    .review(skillID: SkillID(rawValue: id)),
                    .challenge(skillID: SkillID(rawValue: id))
                ]
            )
        }
    }
}

@MainActor
private final class DiscoveryContentRepository: LearningContentRepository {
    let catalog: LearningCatalog

    init(catalog: LearningCatalog) {
        self.catalog = catalog
    }

    func loadCatalog() throws -> LearningCatalog {
        catalog
    }
}

@MainActor
private final class DiscoverySkillRepository: CanonicalSkillRepository {
    let skills: [CanonicalSkill]

    init(skills: [CanonicalSkill]) {
        self.skills = skills
    }

    func loadCanonicalSkills() throws -> [CanonicalSkill] {
        skills
    }
}
