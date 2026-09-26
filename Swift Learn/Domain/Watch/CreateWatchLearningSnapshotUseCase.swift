import Foundation

@MainActor
struct CreateWatchLearningSnapshotUseCase {
    private let loadJourney: LoadLearningJourneyUseCase
    private let loadProfile: LoadLearnerProfileUseCase
    private let loadReviewQueue: LoadReviewQueueUseCase
    private let loadSyncSnapshot: LoadLearningSyncSnapshotUseCase
    private let loadMasteryOverview: LoadMasteryOverviewUseCase
    private let orderChoices: OrderActivityChoicesUseCase
    private let clock: any LearningClock

    init(
        loadJourney: LoadLearningJourneyUseCase,
        loadProfile: LoadLearnerProfileUseCase,
        loadReviewQueue: LoadReviewQueueUseCase,
        loadSyncSnapshot: LoadLearningSyncSnapshotUseCase,
        loadMasteryOverview: LoadMasteryOverviewUseCase,
        orderChoices: OrderActivityChoicesUseCase = OrderActivityChoicesUseCase(
            randomizer: IdentityChoiceOrder()
        ),
        clock: any LearningClock
    ) {
        self.loadJourney = loadJourney
        self.loadProfile = loadProfile
        self.loadReviewQueue = loadReviewQueue
        self.loadSyncSnapshot = loadSyncSnapshot
        self.loadMasteryOverview = loadMasteryOverview
        self.orderChoices = orderChoices
        self.clock = clock
    }

    func execute() throws -> WatchLearningSnapshot {
        let journey = try loadJourney.execute()
        let profile = try loadProfile.execute().profile
        let syncSnapshot = try loadSyncSnapshot.execute()
        let reviews = try loadReviewQueue.execute()
        let nextLesson = journey.catalog.lessons.first { lesson in
            !journey.isCompleted(lessonID: lesson.id)
                && journey.isUnlocked(lessonID: lesson.id)
        }

        return WatchLearningSnapshot(
            learnerName: profile.displayName,
            completedLessonCount: journey.completedLessonCount,
            totalLessonCount: journey.totalLessonCount,
            dueReviewCount: reviews.count,
            reviewItems: reviews.compactMap {
                // Seeded on the reset generation, so a snapshot republished
                // while the learner is answering keeps the same order.
                makeReviewSnapshot(
                    from: $0,
                    attemptNumber: syncSnapshot.resetGeneration
                )
            },
            progressDetail: makeProgressDetail(
                journey: journey,
                mastery: try loadMasteryOverview.execute()
            ),
            nextLesson: nextLesson.map {
                WatchNextLessonSnapshot(
                    id: $0.id,
                    title: $0.title,
                    objective: $0.objective
                )
            },
            resetGeneration: syncSnapshot.resetGeneration,
            acknowledgedEventIDs: syncSnapshot.appliedEventIDs,
            generatedAt: clock.now
        )
    }

    /// The current level is the first level holding an incomplete lesson,
    /// otherwise the last level of a finished journey.
    private func makeProgressDetail(
        journey: LearningJourney,
        mastery: MasteryOverview
    ) -> WatchProgressDetailSnapshot? {
        let currentLevel = journey.catalog.levels.first { level in
            level.lessons.contains { !journey.isCompleted(lessonID: $0.id) }
        } ?? journey.catalog.levels.last
        guard let currentLevel else { return nil }

        return WatchProgressDetailSnapshot(
            levelTitle: currentLevel.title,
            levelCompletedLessonCount: currentLevel.lessons.count {
                journey.isCompleted(lessonID: $0.id)
            },
            levelTotalLessonCount: currentLevel.lessons.count,
            trackedSkillCount: mastery.snapshots.count,
            proficientSkillCount: mastery.proficientCount,
            masteredSkillCount: mastery.masteredCount
        )
    }

    private func makeReviewSnapshot(
        from item: ReviewItem,
        attemptNumber: Int
    ) -> WatchReviewItemSnapshot? {
        let activity = item.lesson.activity
        guard let correctChoiceID = activity.correctChoiceID,
              activity.choices.count >= 2,
              activity.choices.contains(where: { $0.id == correctChoiceID }) else {
            return nil
        }

        return WatchReviewItemSnapshot(
            skillID: item.skill.id.rawValue,
            lessonID: item.lesson.id,
            activityID: LearningActivityID.review(
                skillID: item.skill.id
            ).rawValue,
            title: item.skill.title,
            prompt: activity.prompt,
            choices: orderChoices.execute(
                activity.choices.map {
                    WatchReviewChoiceSnapshot(id: $0.id, text: $0.code)
                },
                seed: OrderActivityChoicesUseCase.seed(
                    questionID: item.lesson.id,
                    attemptNumber: attemptNumber
                )
            ),
            correctChoiceID: correctChoiceID,
            correctFeedback: item.lesson.correctFeedback,
            incorrectFeedback: item.lesson.incorrectFeedback
        )
    }
}
