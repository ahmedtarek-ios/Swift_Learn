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

    var draftDisplayName = LearnerProfile.defaultProfile.displayName
    var draftAvatar = LearnerProfile.defaultProfile.avatar
    var draftAppearance = LearnerProfile.defaultProfile.appearance
    var draftMotionPreference = LearnerProfile.defaultProfile.motionPreference

    private let loadProfile: LoadLearnerProfileUseCase
    private let updateProfile: UpdateLearnerProfileUseCase

    init(
        loadProfile: LoadLearnerProfileUseCase,
        updateProfile: UpdateLearnerProfileUseCase
    ) {
        self.loadProfile = loadProfile
        self.updateProfile = updateProfile
    }

    func load() {
        loadState = .loading

        do {
            let snapshot = try loadProfile.execute()
            apply(snapshot)
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
