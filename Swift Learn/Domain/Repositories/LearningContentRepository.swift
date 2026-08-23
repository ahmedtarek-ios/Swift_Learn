//
//  LearningContentRepository.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
protocol LearningContentRepository {
    func loadCatalog() throws -> LearningCatalog
}
