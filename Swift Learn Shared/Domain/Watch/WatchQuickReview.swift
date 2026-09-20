import Foundation

struct WatchQuickReviewSubmission: Equatable, Sendable {
    let isCorrect: Bool
    let feedback: String
    let eventID: UUID
}

enum WatchQuickReviewDomainError: LocalizedError, Equatable {
    case invalidChoice(String)
    case missingDeviceID

    var errorDescription: String? {
        switch self {
        case let .invalidChoice(id):
            "Unknown review choice: \(id)."
        case .missingDeviceID:
            "Apple Watch has no learning-sync device identifier."
        }
    }
}

@MainActor
protocol WatchQuickReviewClock {
    var now: Date { get }
}

@MainActor
protocol WatchQuickReviewIDGenerating {
    func next() -> UUID
}

@MainActor
protocol WatchDeviceIDProviding {
    func deviceID() -> String
}

@MainActor
struct SubmitWatchQuickReviewAnswerUseCase {
    private let submitEvent: any WatchLearningEventSubmitting
    private let loadSyncSnapshot: LoadLearningSyncSnapshotUseCase
    private let clock: any WatchQuickReviewClock
    private let idGenerator: any WatchQuickReviewIDGenerating
    private let deviceIDProvider: any WatchDeviceIDProviding

    init(
        submitEvent: any WatchLearningEventSubmitting,
        loadSyncSnapshot: LoadLearningSyncSnapshotUseCase,
        clock: any WatchQuickReviewClock,
        idGenerator: any WatchQuickReviewIDGenerating,
        deviceIDProvider: any WatchDeviceIDProviding
    ) {
        self.submitEvent = submitEvent
        self.loadSyncSnapshot = loadSyncSnapshot
        self.clock = clock
        self.idGenerator = idGenerator
        self.deviceIDProvider = deviceIDProvider
    }

    func execute(
        item: WatchReviewItemSnapshot,
        choiceID: String
    ) throws -> WatchQuickReviewSubmission {
        guard item.choices.contains(where: { $0.id == choiceID }) else {
            throw WatchQuickReviewDomainError.invalidChoice(choiceID)
        }
        let deviceID = deviceIDProvider.deviceID().trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard deviceID.isEmpty == false else {
            throw WatchQuickReviewDomainError.missingDeviceID
        }

        let isCorrect = choiceID == item.correctChoiceID
        let now = clock.now
        let attempt = LearningSyncAttempt(
            id: idGenerator.next(),
            lessonID: item.lessonID,
            skillID: item.skillID,
            activityID: item.activityID,
            outcome: isCorrect ? .correct : .incorrect,
            errorCategory: isCorrect ? nil : .incorrectChoice,
            recordedAt: now
        )
        let event = LearningSyncEvent(
            id: idGenerator.next(),
            deviceID: deviceID,
            resetGeneration: try loadSyncSnapshot.execute().resetGeneration,
            createdAt: now,
            kind: .attemptRecorded,
            attempt: attempt
        )
        try submitEvent.submit(event)

        return WatchQuickReviewSubmission(
            isCorrect: isCorrect,
            feedback: isCorrect ? item.correctFeedback : item.incorrectFeedback,
            eventID: event.id
        )
    }
}
