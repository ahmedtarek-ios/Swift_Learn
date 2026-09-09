import Testing
@testable import Swift_Learn

@MainActor
struct SupplementalLearningTests {
    @Test
    func bundledTracksAreCompleteAndExplicitlySourceLocked() throws {
        let tracks = try LoadSupplementalTracksUseCase(
            repository: BundledSupplementalTrackRepository()
        ).execute()

        #expect(
            tracks.map(\.id) == [
                "supplemental.testing.automation",
                "supplemental.architecture.swift-learn",
                "supplemental.persistence.apple",
                "supplemental.architecture.patterns",
                "supplemental.security.privacy",
                "supplemental.professional.practice",
                "supplemental.release.readiness"
            ]
        )
        #expect(tracks.allSatisfy { $0.source.references.isEmpty == false })
        #expect(tracks.allSatisfy { $0.lessons.isEmpty == false })
        #expect(
            tracks.flatMap(\.lessons).allSatisfy {
                $0.id.hasPrefix("supplemental.") && $0.practice.choices.count >= 2
            }
        )
    }

    @Test
    func duplicateSupplementalLessonIDsAreRejected() {
        let lesson = SupplementalLesson(
            id: "supplemental.duplicate",
            title: "Duplicate",
            objective: "Reject duplicate identity.",
            keyPoints: ["One identity"],
            practice: makePractice()
        )
        let source = SupplementalSourceLock(
            id: "source",
            title: "Source",
            references: ["source#reference"]
        )
        let repository = SupplementalFixtureRepository(
            tracks: [
                SupplementalTrack(
                    id: "supplemental.one",
                    title: "One",
                    summary: "One",
                    source: source,
                    lessons: [lesson]
                ),
                SupplementalTrack(
                    id: "supplemental.two",
                    title: "Two",
                    summary: "Two",
                    source: source,
                    lessons: [lesson]
                )
            ]
        )

        #expect(
            throws: SupplementalLearningError.duplicateLessonID("supplemental.duplicate")
        ) {
            try LoadSupplementalTracksUseCase(repository: repository).execute()
        }
    }

    @Test(
        arguments: [
            ("track", "supplemental.lesson", SupplementalLearningError.invalidTrackID("track")),
            (
                "supplemental.track",
                "lesson",
                SupplementalLearningError.invalidLessonID("lesson")
            )
        ]
    )
    func identifiersMustUseSupplementalNamespace(
        trackID: String,
        lessonID: String,
        expectedError: SupplementalLearningError
    ) {
        let repository = SupplementalFixtureRepository(
            tracks: [
                SupplementalTrack(
                    id: trackID,
                    title: "Track",
                    summary: "Track",
                    source: SupplementalSourceLock(
                        id: "source",
                        title: "Source",
                        references: ["source#reference"]
                    ),
                    lessons: [
                        SupplementalLesson(
                            id: lessonID,
                            title: "Lesson",
                            objective: "Validate namespace.",
                            keyPoints: ["One namespace"],
                            practice: makePractice()
                        )
                    ]
                )
            ]
        )

        #expect(throws: expectedError) {
            try LoadSupplementalTracksUseCase(repository: repository).execute()
        }
    }

    @Test
    func invalidPracticeIsRejected() {
        let lesson = SupplementalLesson(
            id: "supplemental.invalid-practice",
            title: "Invalid",
            objective: "Reject invalid practice.",
            keyPoints: ["Valid choices"],
            practice: SupplementalPractice(
                prompt: "Invalid?",
                choices: [SupplementalPracticeChoice(id: "only", text: "Only")],
                correctChoiceID: "missing",
                correctFeedback: "Correct",
                incorrectFeedback: "Incorrect"
            )
        )
        let repository = SupplementalFixtureRepository(
            tracks: [
                SupplementalTrack(
                    id: "supplemental.invalid",
                    title: "Invalid",
                    summary: "Invalid",
                    source: SupplementalSourceLock(
                        id: "source",
                        title: "Source",
                        references: ["source#reference"]
                    ),
                    lessons: [lesson]
                )
            ]
        )

        #expect(
            throws: SupplementalLearningError.invalidPractice(lesson.id)
        ) {
            try LoadSupplementalTracksUseCase(repository: repository).execute()
        }
    }

    @Test
    func practiceEvaluationReturnsSourceFeedback() throws {
        let track = try #require(
            try LoadSupplementalTracksUseCase(
                repository: BundledSupplementalTrackRepository()
            ).execute().first
        )
        let lesson = try #require(track.lessons.first)
        let useCase = EvaluateSupplementalPracticeUseCase()

        #expect(
            useCase.execute(choiceID: "correct", lesson: lesson)
                == .correct(lesson.practice.correctFeedback)
        )
        #expect(
            useCase.execute(choiceID: "incorrect", lesson: lesson)
                == .incorrect(lesson.practice.incorrectFeedback)
        )
    }

    @Test
    func supplementalViewModelExposesLoadedTrack() {
        let viewModel = SupplementalTracksViewModel(
            loadTracks: LoadSupplementalTracksUseCase(
                repository: BundledSupplementalTrackRepository()
            ),
            evaluatePractice: EvaluateSupplementalPracticeUseCase()
        )

        viewModel.load()
        let lesson = viewModel.tracks[0].lessons[0]
        viewModel.select(choiceID: "correct", for: lesson.id)
        viewModel.submit(lesson)

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.tracks.count == 7)
        #expect(viewModel.selectedChoiceByLessonID[lesson.id] == "correct")
        #expect(
            viewModel.resultByLessonID[lesson.id]
                == .correct(lesson.practice.correctFeedback)
        )
    }

    private func makePractice() -> SupplementalPractice {
        SupplementalPractice(
            prompt: "Choose.",
            choices: [
                SupplementalPracticeChoice(id: "correct", text: "Correct"),
                SupplementalPracticeChoice(id: "incorrect", text: "Incorrect")
            ],
            correctChoiceID: "correct",
            correctFeedback: "Correct",
            incorrectFeedback: "Incorrect"
        )
    }
}

@MainActor
private final class SupplementalFixtureRepository: SupplementalTrackRepository {
    let tracks: [SupplementalTrack]

    init(tracks: [SupplementalTrack]) {
        self.tracks = tracks
    }

    func loadTracks() throws -> [SupplementalTrack] {
        tracks
    }
}
