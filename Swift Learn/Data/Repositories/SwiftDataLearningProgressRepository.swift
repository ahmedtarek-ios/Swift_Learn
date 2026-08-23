//
//  SwiftDataLearningProgressRepository.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataLearningProgressRepository: LearningProgressRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadCompletedLessonIDs() throws -> Set<String> {
        let records = try modelContext.fetch(FetchDescriptor<LessonProgressRecord>())
        return Set(records.map(\.lessonID))
    }

    func markCompleted(lessonID: String) throws {
        let records = try modelContext.fetch(FetchDescriptor<LessonProgressRecord>())
        guard !records.contains(where: { $0.lessonID == lessonID }) else {
            return
        }

        modelContext.insert(
            LessonProgressRecord(lessonID: lessonID, completedAt: .now)
        )
        try modelContext.save()
    }
}
