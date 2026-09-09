import Foundation

@MainActor
struct CreateWatchLearningSnapshotUseCase {
    private let loadJourney: LoadLearningJourneyUseCase
    private let loadProfile: LoadLearnerProfileUseCase
    private let loadReviewQueue: LoadReviewQueueUseCase
    private let clock: any LearningClock

    init(
        loadJourney: LoadLearningJourneyUseCase,
        loadProfile: LoadLearnerProfileUseCase,
        loadReviewQueue: LoadReviewQueueUseCase,
        clock: any LearningClock
    ) {
        self.loadJourney = loadJourney
        self.loadProfile = loadProfile
        self.loadReviewQueue = loadReviewQueue
        self.clock = clock
    }

    func execute() throws -> WatchLearningSnapshot {
        let journey = try loadJourney.execute()
        let profile = try loadProfile.execute().profile
        let nextLesson = journey.catalog.lessons.first { lesson in
            !journey.isCompleted(lessonID: lesson.id)
                && journey.isUnlocked(lessonID: lesson.id)
        }

        return WatchLearningSnapshot(
            learnerName: profile.displayName,
            completedLessonCount: journey.completedLessonCount,
            totalLessonCount: journey.totalLessonCount,
            dueReviewCount: try loadReviewQueue.execute().count,
            nextLesson: nextLesson.map {
                WatchNextLessonSnapshot(
                    id: $0.id,
                    title: $0.title,
                    objective: $0.objective
                )
            },
            generatedAt: clock.now
        )
    }
}
