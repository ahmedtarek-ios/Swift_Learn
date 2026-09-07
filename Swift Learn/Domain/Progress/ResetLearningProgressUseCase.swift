//
//  ResetLearningProgressUseCase.swift
//  Swift Learn
//
//  Created by Codex on 31/08/2026.
//

@MainActor
struct ResetLearningProgressUseCase {
    private let resetRepository: any LearningResetRepository

    init(resetRepository: any LearningResetRepository) {
        self.resetRepository = resetRepository
    }

    func execute() throws {
        try resetRepository.resetLearningProgress()
    }
}
