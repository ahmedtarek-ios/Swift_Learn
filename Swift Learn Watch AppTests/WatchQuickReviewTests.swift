import Foundation
import Testing
@testable import Swift_Learn_Watch_App

@MainActor
struct WatchQuickReviewTests {
    @Test
    func submitQueuesCanonicalCorrectReviewAttempt() throws {
        let repository = InMemoryLearningSyncRepository(
            snapshot: LearningSyncSnapshot(
                resetGeneration: 3,
                completedLessonIDs: [],
                attempts: [],
                appliedEventIDs: []
            )
        )
        let useCase = makeSubmitUseCase(repository: repository)

        let submission = try useCase.execute(
            item: makeItem(),
            choiceID: "let"
        )

        #expect(submission.isCorrect)
        #expect(submission.feedback == "Correct — let creates a constant.")
        let event = try #require(repository.loadPendingEvents().first)
        #expect(event.id == submission.eventID)
        #expect(event.deviceID == "watch-test")
        #expect(event.resetGeneration == 3)
        #expect(event.kind == .attemptRecorded)
        #expect(event.attempt?.lessonID == "swift.bindings.constants")
        #expect(event.attempt?.skillID == "swift.bindings.constants")
        #expect(event.attempt?.activityID == "review.swift.bindings.constants")
        #expect(event.attempt?.outcome == .correct)
        #expect(event.attempt?.errorCategory == nil)
    }

    @Test
    func submitRejectsUnknownChoiceWithoutQueueing() throws {
        let repository = InMemoryLearningSyncRepository()
        let useCase = makeSubmitUseCase(repository: repository)

        #expect(
            throws: WatchQuickReviewDomainError.invalidChoice("unknown")
        ) {
            try useCase.execute(item: makeItem(), choiceID: "unknown")
        }
        #expect(repository.loadPendingEvents().isEmpty)
    }

    @Test
    func incorrectAnswerShowsFeedbackAndCanRetry() throws {
        let repository = InMemoryLearningSyncRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.start(items: [makeItem()], resetGeneration: 0)

        viewModel.selectChoice("var")
        viewModel.submit()

        #expect(
            viewModel.phase == .feedback(
                WatchQuickReviewViewModel.Feedback(
                    isCorrect: false,
                    message: "Try again — var creates a variable.",
                    isSessionComplete: false
                )
            )
        )
        #expect(viewModel.errorHapticSequence == 1)
        #expect(viewModel.pendingSyncEventCount == 1)
        #expect(viewModel.currentItem?.skillID == "swift.bindings.constants")

        viewModel.retry()

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.selectedChoiceID == nil)
    }

    @Test
    func correctAnswerCompletesSessionAndQueuesOnce() throws {
        let repository = InMemoryLearningSyncRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.start(items: [makeItem()], resetGeneration: 0)

        viewModel.selectChoice("let")
        viewModel.submit()
        viewModel.submit()

        #expect(
            viewModel.phase == .feedback(
                WatchQuickReviewViewModel.Feedback(
                    isCorrect: true,
                    message: "Correct — let creates a constant.",
                    isSessionComplete: true
                )
            )
        )
        #expect(viewModel.successHapticSequence == 1)
        #expect(viewModel.pendingSyncEventCount == 1)
        #expect(viewModel.currentItem == nil)
        #expect(repository.loadPendingEvents().count == 1)
    }

    @Test
    func pendingCorrectReviewStaysCompletedAcrossRelaunch() throws {
        let repository = InMemoryLearningSyncRepository()
        let submit = makeSubmitUseCase(repository: repository)
        _ = try submit.execute(item: makeItem(), choiceID: "let")
        let viewModel = makeViewModel(repository: repository)

        viewModel.start(items: [makeItem()], resetGeneration: 0)

        #expect(viewModel.phase == .empty)
        #expect(viewModel.currentItem == nil)
        #expect(viewModel.pendingSyncEventCount == 1)
    }

    private func makeViewModel(
        repository: InMemoryLearningSyncRepository
    ) -> WatchQuickReviewViewModel {
        WatchQuickReviewViewModel(
            submitAnswer: makeSubmitUseCase(repository: repository),
            loadPendingEvents: LoadPendingLearningSyncEventsUseCase(
                repository: repository
            )
        )
    }

    private func makeSubmitUseCase(
        repository: InMemoryLearningSyncRepository
    ) -> SubmitWatchQuickReviewAnswerUseCase {
        SubmitWatchQuickReviewAnswerUseCase(
            submitEvent: repository,
            loadSyncSnapshot: LoadLearningSyncSnapshotUseCase(
                repository: repository
            ),
            clock: FixedWatchQuickReviewClock(),
            idGenerator: SequenceWatchQuickReviewIDGenerator(),
            deviceIDProvider: FixedWatchDeviceIDProvider()
        )
    }

    private func makeItem() -> WatchReviewItemSnapshot {
        WatchReviewItemSnapshot(
            skillID: "swift.bindings.constants",
            lessonID: "swift.bindings.constants",
            activityID: "review.swift.bindings.constants",
            title: "Constants and Variables",
            prompt: "Which declaration creates a constant?",
            choices: [
                WatchReviewChoiceSnapshot(id: "var", text: "var"),
                WatchReviewChoiceSnapshot(id: "let", text: "let")
            ],
            correctChoiceID: "let",
            correctFeedback: "Correct — let creates a constant.",
            incorrectFeedback: "Try again — var creates a variable."
        )
    }
}

@MainActor
private struct FixedWatchQuickReviewClock: WatchQuickReviewClock {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
}

@MainActor
private final class SequenceWatchQuickReviewIDGenerator:
    WatchQuickReviewIDGenerating {
    private var sequence: UInt64 = 1

    func next() -> UUID {
        defer { sequence += 1 }
        let suffix = String(format: "%012llx", sequence)
        return UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!
    }
}

@MainActor
private struct FixedWatchDeviceIDProvider: WatchDeviceIDProviding {
    func deviceID() -> String { "watch-test" }
}
