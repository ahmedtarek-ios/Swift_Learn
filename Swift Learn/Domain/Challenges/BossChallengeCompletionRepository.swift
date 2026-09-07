//
//  BossChallengeCompletionRepository.swift
//  Swift Learn
//
//  Created by Codex on 07/09/2026.
//

@MainActor
protocol BossChallengeCompletionRepository {
    func record(_ completion: BossChallengeCompletion) throws
    func loadCompletions() throws -> [BossChallengeCompletion]
}
