import Foundation

struct MotivationProgress: Equatable, Sendable {
    let totalXP: Int
    let dailyXP: Int
    let dailyGoalXP: Int
    let weeklyXP: Int
    let weeklyGoalXP: Int
    let streakDays: Int
    let recoveryTokens: Int
}

@MainActor
struct LoadMotivationProgressUseCase {
    private struct Reward {
        let date: Date
        let xp: Int
    }

    private let contentRepository: any LearningContentRepository
    private let progressRepository: any LearningProgressRepository
    private let loadCanonicalSkills: LoadCanonicalSkillsUseCase
    private let attemptRepository: any LearningAttemptRepository
    private let bossCompletionRepository: any BossChallengeCompletionRepository
    private let projectRepository: any LearningProjectRepository
    private let projectSubmissionRepository: any LearningProjectSubmissionRepository
    private let clock: any LearningClock
    private let calendar: Calendar

    init(
        contentRepository: any LearningContentRepository,
        progressRepository: any LearningProgressRepository,
        loadCanonicalSkills: LoadCanonicalSkillsUseCase,
        attemptRepository: any LearningAttemptRepository,
        bossCompletionRepository: any BossChallengeCompletionRepository,
        projectRepository: any LearningProjectRepository,
        projectSubmissionRepository: any LearningProjectSubmissionRepository,
        clock: any LearningClock,
        calendar: Calendar = .current
    ) {
        self.contentRepository = contentRepository
        self.progressRepository = progressRepository
        self.loadCanonicalSkills = loadCanonicalSkills
        self.attemptRepository = attemptRepository
        self.bossCompletionRepository = bossCompletionRepository
        self.projectRepository = projectRepository
        self.projectSubmissionRepository = projectSubmissionRepository
        self.clock = clock
        var mondayFirstCalendar = calendar
        mondayFirstCalendar.firstWeekday = 2
        self.calendar = mondayFirstCalendar
    }

    func execute() throws -> MotivationProgress {
        let now = clock.now
        let catalog = try contentRepository.loadCatalog()
        let lessonsByID = Dictionary(uniqueKeysWithValues: catalog.lessons.map { ($0.id, $0) })
        let skillsByID = Dictionary(
            uniqueKeysWithValues: try loadCanonicalSkills.execute().map { ($0.id, $0) }
        )
        let completedLessonIDs = try progressRepository.loadCompletedLessonIDs()
        var rewards: [Reward] = []
        var rewardedLessons = Set<String>()
        var rewardedAttempts = Set<UUID>()

        for attempt in try attemptRepository.loadAllAttempts().sorted(by: {
            $0.recordedAt < $1.recordedAt
        }) {
            let evidence = attempt.evidence
            guard attempt.recordedAt <= now,
                  evidence.outcome == .correct,
                  let skill = skillsByID[evidence.skillID],
                  let lesson = lessonsByID[evidence.lessonID],
                  skill.lessonIDs.contains(evidence.lessonID),
                  skill.activityIDs.contains(evidence.activityID),
                  rewardedAttempts.insert(attempt.id).inserted else {
                continue
            }

            if evidence.activityID == lesson.activityID,
               completedLessonIDs.contains(lesson.id),
               rewardedLessons.insert(lesson.id).inserted {
                rewards.append(Reward(date: attempt.recordedAt, xp: 20))
            } else if evidence.activityID == .review(skillID: skill.id) {
                rewards.append(Reward(date: attempt.recordedAt, xp: 10))
            }
        }

        let levelIDs = Set(catalog.levels.map(\.id))
        var rewardedChallenges = Set<String>()
        for completion in try bossCompletionRepository.loadCompletions().sorted(by: {
            $0.completedAt < $1.completedAt
        }) where completion.completedAt <= now
            && levelIDs.contains(completion.levelID)
            && completion.challengeID == "boss.\(completion.levelID)"
            && rewardedChallenges.insert(completion.challengeID).inserted {
            rewards.append(Reward(date: completion.completedAt, xp: 100))
        }

        for project in try projectRepository.loadProjects() {
            if let firstPass = try projectSubmissionRepository
                .loadSubmissions(projectID: project.id)
                .filter({ isValidPass($0, for: project) && $0.submittedAt <= now })
                .min(by: { $0.submittedAt < $1.submittedAt }) {
                rewards.append(Reward(date: firstPass.submittedAt, xp: 150))
            }
        }

        let today = calendar.startOfDay(for: now)
        let week = calendar.dateInterval(of: .weekOfYear, for: now)
        let dailyXP = rewards.filter { calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.xp }
        let weeklyXP = rewards.filter {
            guard let week else { return false }
            return $0.date >= week.start && $0.date < week.end
        }.reduce(0) { $0 + $1.xp }
        let xpByDay = Dictionary(grouping: rewards, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.xp } }
        let (streakDays, recoveryTokens) = streak(asOf: today, xpByDay: xpByDay)

        return MotivationProgress(
            totalXP: rewards.reduce(0) { $0 + $1.xp },
            dailyXP: dailyXP,
            dailyGoalXP: 20,
            weeklyXP: weeklyXP,
            weeklyGoalXP: 100,
            streakDays: streakDays,
            recoveryTokens: recoveryTokens
        )
    }

    private func isValidPass(
        _ submission: LearningProjectSubmission,
        for project: LearningProject
    ) -> Bool {
        guard submission.projectID == project.id,
              submission.isPassed,
              submission.results.count == project.requirements.count else {
            return false
        }
        let resultsByID = Dictionary(grouping: submission.results, by: \.requirementID)
        return project.requirements.allSatisfy { requirement in
            guard let results = resultsByID[requirement.id],
                  results.count == 1,
                  let result = results.first else { return false }
            return result.lessonID == requirement.lesson.id
                && result.skillID == requirement.skillID
                && result.selectedChoiceID == requirement.lesson.correctChoiceID
        }
    }

    private func streak(asOf today: Date, xpByDay: [Date: Int]) -> (Int, Int) {
        guard let firstDay = xpByDay.keys.min() else { return (0, 0) }
        var day = firstDay
        var streakDays = 0
        var qualifyingDaysSinceToken = 0
        var recoveryTokens = 0

        while day <= today {
            let qualifies = (xpByDay[day] ?? 0) >= 20
            if qualifies {
                streakDays += 1
                qualifyingDaysSinceToken += 1
                if qualifyingDaysSinceToken == 7 && recoveryTokens == 0 {
                    recoveryTokens = 1
                    qualifyingDaysSinceToken = 0
                }
            } else if day < today {
                if recoveryTokens > 0 {
                    recoveryTokens -= 1
                    qualifyingDaysSinceToken = 0
                } else {
                    streakDays = 0
                    qualifyingDaysSinceToken = 0
                }
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day),
                  nextDay > day else { break }
            day = nextDay
        }
        return (streakDays, recoveryTokens)
    }
}
