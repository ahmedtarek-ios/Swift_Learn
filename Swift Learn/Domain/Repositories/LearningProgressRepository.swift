//
//  LearningProgressRepository.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
protocol LearningProgressRepository {
    func loadCompletedLessonIDs() throws -> Set<String>
    func markCompleted(lessonID: String) throws
}
