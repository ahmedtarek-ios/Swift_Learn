import Foundation
import Testing
@testable import Swift_Learn

@MainActor
struct GitLearningViewModelTests {
    @Test
    func loadExposesTrackAndOpensTheFirstQuestion() throws {
        let harness = try Harness()

        harness.viewModel.load()

        #expect(harness.viewModel.track?.totalLessonCount == harness.catalog.lessonCount)
        #expect(harness.viewModel.currentLesson?.id == harness.catalog.lessons[0].id)
        #expect(harness.viewModel.canSubmit == false)
        #expect(
            harness.viewModel.progressSummary
                == "0 of \(harness.catalog.lessonCount) commands"
        )
    }

    @Test
    func loadFailureExposesRetryableError() {
        let viewModel = GitLearningViewModel(
            loadTrack: LoadGitLearningTrackUseCase(
                contentRepository: FailingGitContentRepository(),
                progressRepository: InMemoryGitTrackRepository()
            ),
            submitAnswer: SubmitGitAnswerUseCase(
                contentRepository: FailingGitContentRepository(),
                progressRepository: InMemoryGitTrackRepository(),
                attemptRepository: InMemoryGitTrackRepository(),
                clock: GitViewModelTestClock()
            ),
            resetProgress: ResetGitTrackProgressUseCase(
                repository: InMemoryGitTrackRepository()
            )
        )

        viewModel.load()

        #expect(
            viewModel.loadState
                == .failed(GitContentError.resourceNotFound("test").localizedDescription)
        )
    }

    @Test
    func incorrectThenCorrectAnswerCompletesAndAdvances() throws {
        let harness = try Harness()
        harness.viewModel.load()
        let first = try #require(harness.viewModel.currentLesson)
        let wrong = try #require(first.choices.first { $0.id != first.correctChoiceID })

        harness.viewModel.select(choiceID: wrong.id)
        #expect(harness.viewModel.canSubmit)
        harness.viewModel.submit(lessonID: first.id)

        #expect(harness.viewModel.answerResult?.isCorrect == false)
        #expect(harness.viewModel.track?.completedLessonCount == 0)

        harness.viewModel.retryCurrentQuestion()
        #expect(harness.viewModel.answerResult == nil)
        #expect(harness.viewModel.selectedChoiceID == nil)

        harness.viewModel.select(choiceID: first.correctChoiceID)
        harness.viewModel.submit(lessonID: first.id)

        #expect(harness.viewModel.answerResult?.isCorrect == true)
        #expect(harness.viewModel.answerResult?.didComplete == true)
        #expect(harness.viewModel.track?.completedLessonCount == 1)

        harness.viewModel.continueToNextQuestion()
        #expect(harness.viewModel.currentLesson?.id == harness.catalog.lessons[1].id)
        #expect(harness.viewModel.answerResult == nil)
    }

    @Test
    func lockedQuestionsCannotBeOpened() throws {
        let harness = try Harness()
        harness.viewModel.load()

        harness.viewModel.open(lessonID: harness.catalog.lessons[2].id)

        #expect(harness.viewModel.currentLesson?.id == harness.catalog.lessons[0].id)
    }

    @Test
    func beginningACommandClearsStaleSelectionAndFeedback() throws {
        let harness = try Harness()
        harness.viewModel.load()
        let first = try #require(harness.viewModel.currentLesson)
        let wrong = try #require(first.choices.first { $0.id != first.correctChoiceID })
        harness.viewModel.select(choiceID: wrong.id)
        harness.viewModel.submit(lessonID: first.id)
        #expect(harness.viewModel.answerResult != nil)

        harness.viewModel.beginLesson(id: first.id)

        #expect(harness.viewModel.currentLesson?.id == first.id)
        #expect(harness.viewModel.selectedChoiceID == nil)
        #expect(harness.viewModel.answerResult == nil)
        #expect(harness.viewModel.canSubmit(lessonID: first.id) == false)
    }

    @Test
    func completingFinalQuestionRevealsTrackCompletion() throws {
        let harness = try Harness(completedLessonCount: 138)
        harness.viewModel.load()
        let finalLesson = try #require(harness.catalog.lessons.last)

        #expect(harness.viewModel.currentLesson?.id == finalLesson.id)
        harness.viewModel.select(choiceID: finalLesson.correctChoiceID)
        harness.viewModel.submit(lessonID: finalLesson.id)

        #expect(harness.viewModel.track?.isTrackComplete == true)
        #expect(harness.viewModel.nextLesson == nil)
        let navigationRevision = harness.viewModel.navigationRevision
        harness.viewModel.finishTrack()
        #expect(harness.viewModel.currentLesson == nil)
        #expect(harness.viewModel.isTrackComplete)
        #expect(harness.viewModel.navigationRevision == navigationRevision + 1)
    }

    @Test
    func resetCancellationChangesNothing() throws {
        let harness = try Harness(completedLessonCount: 1)
        harness.viewModel.load()

        harness.viewModel.requestReset()
        #expect(harness.viewModel.resetState == .confirming)
        harness.viewModel.cancelReset()

        #expect(harness.viewModel.resetState == .idle)
        #expect(harness.viewModel.track?.completedLessonCount == 1)
    }

    @Test
    func confirmedResetClearsGitProgressAndReloadsTheFirstQuestion() throws {
        let harness = try Harness(completedLessonCount: 1)
        harness.viewModel.load()

        let navigationRevision = harness.viewModel.navigationRevision
        harness.viewModel.requestReset()
        harness.viewModel.confirmReset()

        #expect(harness.viewModel.resetState == .succeeded)
        #expect(harness.viewModel.track?.completedLessonCount == 0)
        #expect(harness.viewModel.currentLesson?.id == harness.catalog.lessons[0].id)
        #expect(harness.viewModel.navigationRevision == navigationRevision + 1)

        harness.viewModel.acknowledgeResetOutcome()
        #expect(harness.viewModel.resetState == .idle)
    }

    @Test
    func resetFailureKeepsProgressAndExposesAnError() throws {
        let harness = try Harness(
            completedLessonCount: 1,
            resetRepository: FailingGitResetRepository()
        )
        harness.viewModel.load()

        harness.viewModel.requestReset()
        harness.viewModel.confirmReset()

        #expect(
            harness.viewModel.resetState
                == .failed(GitResetFixtureError.resetUnavailable.localizedDescription)
        )
        #expect(harness.viewModel.track?.completedLessonCount == 1)
    }

    // MARK: - Harness

    @MainActor
    private struct Harness {
        let catalog: GitCommandCatalog
        let viewModel: GitLearningViewModel

        init(
            completedLessonCount: Int = 0,
            resetRepository: (any GitTrackResetRepository)? = nil
        ) throws {
            let bundle = Bundle(for: GitViewModelBundleToken.self)
            let url = try #require(
                bundle.url(forResource: "git-commands-foundations", withExtension: "json")
                    ?? Bundle.main.url(
                        forResource: "git-commands-foundations",
                        withExtension: "json"
                    )
            )
            let data = try Data(contentsOf: url)
            let content = BundledGitCommandRepository(data: data)
            catalog = try content.loadCatalog()
            let completedLessonIDs = Set(
                catalog.lessons.prefix(completedLessonCount).map(\.id)
            )
            let store = InMemoryGitTrackRepository(
                completedLessonIDs: completedLessonIDs
            )
            viewModel = GitLearningViewModel(
                loadTrack: LoadGitLearningTrackUseCase(
                    contentRepository: content,
                    progressRepository: store
                ),
                submitAnswer: SubmitGitAnswerUseCase(
                    contentRepository: content,
                    progressRepository: store,
                    attemptRepository: store,
                    clock: GitViewModelTestClock()
                ),
                resetProgress: ResetGitTrackProgressUseCase(
                    repository: resetRepository ?? store
                )
            )
        }
    }
}

private final class GitViewModelBundleToken {}

@MainActor
private struct GitViewModelTestClock: LearningClock {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
}

@MainActor
private struct FailingGitContentRepository: GitCommandContentRepository {
    func loadCatalog() throws -> GitCommandCatalog {
        throw GitContentError.resourceNotFound("test")
    }
}

enum GitResetFixtureError: LocalizedError, Equatable {
    case resetUnavailable

    var errorDescription: String? { "Git reset is unavailable." }
}

@MainActor
private struct FailingGitResetRepository: GitTrackResetRepository {
    func resetGitProgress() throws {
        throw GitResetFixtureError.resetUnavailable
    }
}
