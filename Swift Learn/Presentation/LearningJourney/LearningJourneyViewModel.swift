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
    private(set) var selectedChoiceID: String?
    private(set) var attemptResult: LessonAttemptResult?
    private(set) var progressEvents: [LearningProgressEvent] = []
    private(set) var recentlyUnlockedLessonID: String?

    private let loadJourney: LoadLearningJourneyUseCase
    private let submitAnswer: SubmitLessonAnswerUseCase
    private let calculateProgressEvents: CalculateLearningProgressEventsUseCase

    init(
        loadJourney: LoadLearningJourneyUseCase,
        submitAnswer: SubmitLessonAnswerUseCase,
        calculateProgressEvents: CalculateLearningProgressEventsUseCase
    ) {
        self.loadJourney = loadJourney
        self.submitAnswer = submitAnswer
        self.calculateProgressEvents = calculateProgressEvents
    }

    func load() {
        loadState = .loading

        do {
            journey = try loadJourney.execute()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectChoice(_ choiceID: String) {
        selectedChoiceID = choiceID
        attemptResult = nil
    }

    func submit(lessonID: String) {
        guard let selectedChoiceID else {
            attemptResult = LessonAttemptResult(
                isCorrect: false,
                feedback: LearningDomainError.choiceNotFound.localizedDescription
            )
            return
        }

        do {
            let journeyBeforeSubmission = journey
            attemptResult = try submitAnswer.execute(
                lessonID: lessonID,
                choiceID: selectedChoiceID
            )
            if attemptResult?.isCorrect == true,
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
        selectedChoiceID = nil
        attemptResult = nil
    }

    func nextLesson(after lessonID: String) -> LearningLesson? {
        journey?.nextLesson(after: lessonID)
    }

    var currentAchievement: AchievementProgress? {
        progressEvents.compactMap { event -> AchievementProgress? in
            guard case let .achievementEarned(achievement) = event else { return nil }
            return achievement
        }.first
    }

    func dismissCurrentAchievement() {
        guard let currentAchievement else { return }
        progressEvents.removeAll { event in
            guard case let .achievementEarned(achievement) = event else { return false }
            return achievement.id == currentAchievement.id
        }
    }
}
