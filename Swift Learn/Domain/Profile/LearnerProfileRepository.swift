//
//  LearnerProfileRepository.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

@MainActor
protocol LearnerProfileRepository {
    func loadProfile() throws -> LearnerProfile
    func saveProfile(_ profile: LearnerProfile) throws
}
