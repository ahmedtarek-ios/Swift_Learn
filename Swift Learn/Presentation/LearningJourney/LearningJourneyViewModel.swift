//
//  LearningJourneyViewModel.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class LearningJourneyViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var journey: LearningJourney?
    private(set) var activitySelection = LearningActivitySelection()
    private(set) var attemptResult: LessonAttemptResult?
    private(set) var progressEvents: [LearningProgressEvent] = []
    private(set) var recentlyUnlockedLessonID: String?
    private(set) var attemptRevision = 0
    private(set) var navigationRevision = 0

    private let loadJourney: LoadLearningJourneyUseCase
    private let submitAnswer: SubmitLessonAnswerUseCase
    private let recordAttempt: RecordLearningAttemptUseCase
    private let calculateProgressEvents: CalculateLearningProgressEventsUseCase

    var selectedChoiceID: String? { activitySelection.choiceID }
    var selectedFragmentIDs: [String] { activitySelection.orderedFragmentIDs }
    var draftText: String { activitySelection.draftText }
    var selectedTokenIDs: [String] { activitySelection.selectedTokenIDs }

    init(
        loadJourney: LoadLearningJourneyUseCase,
        submitAnswer: SubmitLessonAnswerUseCase,
        recordAttempt: RecordLearningAttemptUseCase,
        calculateProgressEvents: CalculateLearningProgressEventsUseCase
    ) {
        self.loadJourney = loadJourney
        self.submitAnswer = submitAnswer
        self.recordAttempt = recordAttempt
        self.calculateProgressEvents = calculateProgressEvents
    }

    func load() {
        loadState = .loading
        activitySelection.reset()
        attemptResult = nil
        progressEvents = []
        recentlyUnlockedLessonID = nil

        do {
            journey = try loadJourney.execute()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func reloadAtJourneyRoot() {
        navigationRevision += 1
        load()
    }

    func selectChoice(_ choiceID: String) {
        activitySelection.selectChoice(choiceID)
        attemptResult = nil
    }

    func selectFragment(_ id: String, lessonID: String) {
        guard let activity = journey?.catalog.lesson(id: lessonID)?.activity else { return }
        activitySelection.appendFragment(id, for: activity)
        attemptResult = nil
    }

    func removeFragment(_ id: String) {
        activitySelection.removeFragment(id)
        attemptResult = nil
    }

    func editText(_ text: String) {
        activitySelection.editText(text)
        attemptResult = nil
    }

    func selectToken(_ id: String, lessonID: String) {
        guard let activity = journey?.catalog.lesson(id: lessonID)?.activity else { return }
        activitySelection.appendToken(id, for: activity)
        attemptResult = nil
    }

    func removeToken(_ id: String, lessonID: String) {
        guard let activity = journey?.catalog.lesson(id: lessonID)?.activity else { return }
        activitySelection.removeToken(id, for: activity)
        attemptResult = nil
    }

    func canSubmit(lessonID: String) -> Bool {
        guard let activity = journey?.catalog.lesson(id: lessonID)?.activity else {
            return false
        }
        return activitySelection.response(for: activity) != nil
    }

    func submit(lessonID: String) {
        guard let lesson = journey?.catalog.lesson(id: lessonID),
              let response = activitySelection.response(for: lesson.activity) else {
            attemptResult = LessonAttemptResult(
                isCorrect: false,
                feedback: LearningDomainError.choiceNotFound.localizedDescription
            )
            return
        }

        do {
            let journeyBeforeSubmission = journey
            let result = try submitAnswer.execute(
                lessonID: lessonID,
                response: response
            )
            try recordAttempt.execute(
                lessonID: lessonID,
                activityID: lesson.activityID,
                outcome: result.isCorrect ? .correct : .incorrect
            )
            attemptRevision += 1
            attemptResult = result

            if result.isCorrect,
               let journeyBeforeSubmission {
                let updatedJourney = try loadJourney.execute()
                journey = updatedJourney
                progressEvents = calculateProgressEvents.execute(
                    before: journeyBeforeSubmission,
                    after: updatedJourney
                )
                recentlyUnlockedLessonID = progressEvents.compactMap { event -> String? in
                    guard case let .lessonUnlocked(lessonID) = event else { return nil }
                    return lessonID
                }.first
            }
        } catch {
            attemptResult = LessonAttemptResult(
                isCorrect: false,
                feedback: error.localizedDescription
            )
        }
    }

    func resetAttempt() {
        activitySelection.reset()
        attemptResult = nil
    }

    func nextLesson(after lessonID: String) -> LearningLesson? {
        journey?.nextLesson(after: lessonID)
    }

    var currentAchievement: AchievementProgress? {
        let achievements = progressEvents.compactMap { event -> AchievementProgress? in
            guard case let .achievementEarned(achievement) = event else { return nil }
            return achievement
        }
        return achievements.first {
            if case .level = $0.definition.kind { return true }
            return false
        } ?? achievements.first
    }

    var currentAchievementHeadline: String {
        guard let currentAchievement,
              case .level = currentAchievement.definition.kind else {
            return "Achievement Unlocked"
        }
        return "Level Complete"
    }

    var progressSummary: String? {
        guard let journey else { return nil }
        return "\(journey.completedLessonCount) of "
            + "\(journey.totalLessonCount) skills practiced"
    }

    func dismissCurrentAchievement() {
        guard let currentAchievement else { return }
        let completedLevel: Bool
        if case .level = currentAchievement.definition.kind {
            completedLevel = true
        } else {
            completedLevel = false
        }
        progressEvents.removeAll { event in
            guard case let .achievementEarned(achievement) = event else { return false }
            if achievement.id == currentAchievement.id { return true }
            // The first-level badge and its level badge describe one completion.
            if completedLevel, case .firstLevel = achievement.definition.kind {
                return true
            }
            return false
        }
    }
}
