//
//  LearnerProfileViewModel.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class LearnerProfileViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var saveState: SaveState = .idle
    private(set) var snapshot: LearnerProfileSnapshot?
    private(set) var masteryOverview: MasteryOverview?

    var draftDisplayName = LearnerProfile.defaultProfile.displayName
    var draftAvatar = LearnerProfile.defaultProfile.avatar
    var draftAppearance = LearnerProfile.defaultProfile.appearance
    var draftMotionPreference = LearnerProfile.defaultProfile.motionPreference

    var progressSummary: String? {
        guard let snapshot else { return nil }
        return "\(snapshot.journey.completedLessonCount) of "
            + "\(snapshot.journey.totalLessonCount) lessons completed"
    }

    private let loadProfile: LoadLearnerProfileUseCase
    private let loadMasteryOverview: LoadMasteryOverviewUseCase
    private let updateProfile: UpdateLearnerProfileUseCase

    init(
        loadProfile: LoadLearnerProfileUseCase,
        loadMasteryOverview: LoadMasteryOverviewUseCase,
        updateProfile: UpdateLearnerProfileUseCase
    ) {
        self.loadProfile = loadProfile
        self.loadMasteryOverview = loadMasteryOverview
        self.updateProfile = updateProfile
    }

    func load() {
        loadState = .loading

        do {
            let snapshot = try loadProfile.execute()
            apply(snapshot)
            masteryOverview = try loadMasteryOverview.execute()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func save() {
        saveState = .saving

        do {
            _ = try updateProfile.execute(
                displayName: draftDisplayName,
                avatar: draftAvatar,
                appearance: draftAppearance,
                motionPreference: draftMotionPreference
            )
            let snapshot = try loadProfile.execute()
            apply(snapshot)
            masteryOverview = try loadMasteryOverview.execute()
            loadState = .loaded
            saveState = .saved
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    private func apply(_ snapshot: LearnerProfileSnapshot) {
        self.snapshot = snapshot
        draftDisplayName = snapshot.profile.displayName
        draftAvatar = snapshot.profile.avatar
        draftAppearance = snapshot.profile.appearance
        draftMotionPreference = snapshot.profile.motionPreference
    }
}
