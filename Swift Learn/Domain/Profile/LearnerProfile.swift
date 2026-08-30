//
//  LearnerProfile.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation

struct LearnerProfile: Equatable, Sendable {
    static let defaultProfile = LearnerProfile(
        displayName: "Swift Learner",
        avatar: .unknown,
        customAvatarImageData: nil,
        appearance: .system,
        motionPreference: .system
    )

    let displayName: String
    let avatar: LearnerAvatar
    let customAvatarImageData: Data?
    let appearance: LearnerAppearance
    let motionPreference: LearnerMotionPreference

    init(
        displayName: String,
        avatar: LearnerAvatar,
        customAvatarImageData: Data? = nil,
        appearance: LearnerAppearance,
        motionPreference: LearnerMotionPreference = .system
    ) {
        self.displayName = displayName
        self.avatar = avatar
        self.customAvatarImageData = customAvatarImageData
        self.appearance = appearance
        self.motionPreference = motionPreference
    }
}

enum LearnerAvatar: String, CaseIterable, Identifiable, Equatable, Sendable {
    case unknown
    case boy
    case girl
    case man
    case woman
    case grandfather
    case grandmother
    case custom

    var id: String { rawValue }

    static var builtInCases: [LearnerAvatar] {
        allCases.filter { $0 != .custom }
    }
}

enum LearnerAppearance: String, CaseIterable, Identifiable, Equatable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

enum LearnerMotionPreference: String, CaseIterable, Identifiable, Equatable, Sendable {
    case system
    case reduced

    var id: String { rawValue }
}

enum AchievementKind: Equatable, Sendable {
    case firstLesson
    case firstLevel
    case lessonMilestone(Int)
    case level(String)
    case sourceCompletion
}

struct AchievementDefinition: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let kind: AchievementKind
}

struct AchievementProgress: Identifiable, Equatable, Sendable {
    let definition: AchievementDefinition
    let completedRequirementCount: Int
    let totalRequirementCount: Int

    var id: String { definition.id }

    var isEarned: Bool {
        totalRequirementCount > 0
            && completedRequirementCount >= totalRequirementCount
    }

    var progress: Double {
        guard totalRequirementCount > 0 else { return 0 }
        return min(
            Double(completedRequirementCount) / Double(totalRequirementCount),
            1
        )
    }
}

struct LearnerProfileSnapshot: Equatable, Sendable {
    let profile: LearnerProfile
    let journey: LearningJourney
    let achievements: [AchievementProgress]

    var completedLevelCount: Int {
        journey.catalog.levels.filter { level in
            !level.lessons.isEmpty
                && level.lessons.allSatisfy {
                    journey.completedLessonIDs.contains($0.id)
                }
        }.count
    }

    var earnedAchievementCount: Int {
        achievements.filter(\.isEarned).count
    }
}

enum LearnerProfileError: LocalizedError, Equatable {
    case emptyDisplayName
    case displayNameTooLong
    case missingCustomAvatarImage

    var errorDescription: String? {
        switch self {
        case .emptyDisplayName:
            "Enter a display name."
        case .displayNameTooLong:
            "Display name must contain 40 characters or fewer."
        case .missingCustomAvatarImage:
            "Choose a Memoji or photo before saving this avatar."
        }
    }
}
