import Foundation

// MARK: - Contracts

@MainActor
protocol GitCommandContentRepository {
    func loadCatalog() throws -> GitCommandCatalog
}

@MainActor
protocol GitTrackProgressRepository {
    func loadCompletedLessonIDs() throws -> Set<String>
    func isCompleted(lessonID: String) throws -> Bool
    func markCompleted(lessonID: String) throws
}

@MainActor
protocol GitTrackAttemptRepository {
    func recordAttempt(
        lessonID: String,
        choiceID: String,
        isCorrect: Bool,
        recordedAt: Date
    ) throws
    func attemptCount() throws -> Int
}

@MainActor
protocol GitTrackResetRepository {
    /// Deletes Git progress and Git attempts only.
    func resetGitProgress() throws
}

// MARK: - Track state

enum GitLessonAvailability: Equatable, Sendable {
    case completed
    case available
    case locked(prerequisiteID: String, prerequisiteTitle: String)
    case unavailable
}

struct GitCategoryProgress: Equatable, Sendable {
    let completedLessonCount: Int
    let totalLessonCount: Int

    var progress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return min(
            max(Double(completedLessonCount) / Double(totalLessonCount), 0),
            1
        )
    }
}

struct GitLearningTrack: Equatable, Sendable {
    let catalog: GitCommandCatalog
    let completedLessonIDs: Set<String>

    var totalLessonCount: Int { catalog.lessonCount }
    var completedLessonCount: Int {
        catalog.lessons.count { completedLessonIDs.contains($0.id) }
    }

    var progress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return min(
            max(Double(completedLessonCount) / Double(totalLessonCount), 0),
            1
        )
    }

    func isCompleted(lessonID: String) -> Bool {
        completedLessonIDs.contains(lessonID)
    }

    func availability(for lessonID: String) -> GitLessonAvailability {
        guard let index = catalog.lessons.firstIndex(where: { $0.id == lessonID })
        else { return .unavailable }
        if completedLessonIDs.contains(lessonID) {
            return .completed
        }
        guard index > 0 else { return .available }

        let prerequisite = catalog.lessons[index - 1]
        guard completedLessonIDs.contains(prerequisite.id) else {
            return .locked(
                prerequisiteID: prerequisite.id,
                prerequisiteTitle: prerequisite.title
            )
        }
        return .available
    }

    func isUnlocked(lessonID: String) -> Bool {
        switch availability(for: lessonID) {
        case .completed, .available:
            true
        case .locked, .unavailable:
            false
        }
    }

    func progress(for category: GitCommandCategory) -> GitCategoryProgress {
        GitCategoryProgress(
            completedLessonCount: category.lessons.count {
                completedLessonIDs.contains($0.id)
            },
            totalLessonCount: category.lessons.count
        )
    }

    var currentLesson: GitCommandLesson? {
        resumeLesson
    }

    var resumeLesson: GitCommandLesson? {
        catalog.lessons.first {
            availability(for: $0.id) == .available
        }
    }

    var isTrackComplete: Bool {
        totalLessonCount > 0 && completedLessonCount == totalLessonCount
    }

    func lesson(after lessonID: String) -> GitCommandLesson? {
        guard let index = catalog.lessons.firstIndex(where: { $0.id == lessonID }),
              index + 1 < catalog.lessons.count else { return nil }
        return catalog.lessons[index + 1]
    }
}

enum GitLearningDomainError: LocalizedError, Equatable {
    case lessonNotFound(String)
    case lessonLocked(String)
    case choiceNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .lessonNotFound(id):
            "Unknown Git question: \(id)."
        case let .lessonLocked(id):
            "Git question \(id) is still locked."
        case let .choiceNotFound(id):
            "Unknown Git answer: \(id)."
        }
    }
}

struct GitAnswerResult: Equatable, Sendable {
    let isCorrect: Bool
    let feedback: String
    let didComplete: Bool
}

// MARK: - Use cases

@MainActor
struct LoadGitLearningTrackUseCase {
    private let contentRepository: any GitCommandContentRepository
    private let progressRepository: any GitTrackProgressRepository
    private let validate = ValidateGitCommandCatalogUseCase()

    init(
        contentRepository: any GitCommandContentRepository,
        progressRepository: any GitTrackProgressRepository
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
    }

    func execute() throws -> GitLearningTrack {
        let catalog = try contentRepository.loadCatalog()
        try validate.execute(catalog)
        return GitLearningTrack(
            catalog: catalog,
            completedLessonIDs: try progressRepository.loadCompletedLessonIDs()
        )
    }
}

@MainActor
struct SubmitGitAnswerUseCase {
    private let contentRepository: any GitCommandContentRepository
    private let progressRepository: any GitTrackProgressRepository
    private let attemptRepository: any GitTrackAttemptRepository
    private let clock: any LearningClock

    init(
        contentRepository: any GitCommandContentRepository,
        progressRepository: any GitTrackProgressRepository,
        attemptRepository: any GitTrackAttemptRepository,
        clock: any LearningClock
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
        self.attemptRepository = attemptRepository
        self.clock = clock
    }

    func execute(lessonID: String, choiceID: String) throws -> GitAnswerResult {
        let catalog = try contentRepository.loadCatalog()
        guard let lesson = catalog.lesson(id: lessonID) else {
            throw GitLearningDomainError.lessonNotFound(lessonID)
        }
        let track = GitLearningTrack(
            catalog: catalog,
            completedLessonIDs: try progressRepository.loadCompletedLessonIDs()
        )
        guard track.isUnlocked(lessonID: lessonID) else {
            throw GitLearningDomainError.lessonLocked(lessonID)
        }
        guard lesson.choices.contains(where: { $0.id == choiceID }) else {
            throw GitLearningDomainError.choiceNotFound(choiceID)
        }

        let isCorrect = choiceID == lesson.correctChoiceID
        try attemptRepository.recordAttempt(
            lessonID: lessonID,
            choiceID: choiceID,
            isCorrect: isCorrect,
            recordedAt: clock.now
        )
        var didComplete = false
        if isCorrect, try progressRepository.isCompleted(lessonID: lessonID) == false {
            try progressRepository.markCompleted(lessonID: lessonID)
            didComplete = true
        }

        return GitAnswerResult(
            isCorrect: isCorrect,
            feedback: isCorrect ? lesson.correctFeedback : lesson.incorrectFeedback,
            didComplete: didComplete
        )
    }
}

@MainActor
struct ResetGitTrackProgressUseCase {
    private let repository: any GitTrackResetRepository

    init(repository: any GitTrackResetRepository) {
        self.repository = repository
    }

    func execute() throws {
        try repository.resetGitProgress()
    }
}
