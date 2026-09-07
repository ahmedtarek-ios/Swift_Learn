//
//  SwiftDataBossChallengeCompletionRepository.swift
//  Swift Learn
//
//  Created by Codex on 07/09/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataBossChallengeCompletionRepository:
    BossChallengeCompletionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func record(_ completion: BossChallengeCompletion) throws {
        let challengeID = completion.challengeID
        let descriptor = FetchDescriptor<BossChallengeCompletionRecord>(
            predicate: #Predicate { $0.challengeID == challengeID }
        )
        guard try modelContext.fetch(descriptor).isEmpty else { return }

        modelContext.insert(
            BossChallengeCompletionRecord(
                challengeID: completion.challengeID,
                levelID: completion.levelID,
                completedAt: completion.completedAt
            )
        )
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func loadCompletions() throws -> [BossChallengeCompletion] {
        let descriptor = FetchDescriptor<BossChallengeCompletionRecord>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { record in
            BossChallengeCompletion(
                challengeID: record.challengeID,
                levelID: record.levelID,
                completedAt: record.completedAt
            )
        }
    }
}
