//
//  LearningRootView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftUI

struct LearningRootView: View {
    private let learningJourneyViewModel: LearningJourneyViewModel
    @State private var learnerProfileViewModel: LearnerProfileViewModel

    init(
        learningJourneyViewModel: LearningJourneyViewModel,
        learnerProfileViewModel: LearnerProfileViewModel
    ) {
        self.learningJourneyViewModel = learningJourneyViewModel
        _learnerProfileViewModel = State(initialValue: learnerProfileViewModel)
    }

    var body: some View {
        TabView {
            LearningJourneyView(viewModel: learningJourneyViewModel)
                .tabItem {
                    Label("Journey", systemImage: "map.fill")
                        .accessibilityIdentifier("journey-tab")
                }

            LearnerProfileView(viewModel: learnerProfileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                        .accessibilityIdentifier("profile-tab")
                }
        }
        .preferredColorScheme(preferredColorScheme)
        .environment(
            \.learnerMotionPreference,
            learnerProfileViewModel.snapshot?.profile.motionPreference ?? .system
        )
        .task {
            if learnerProfileViewModel.loadState == .idle {
                learnerProfileViewModel.load()
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch learnerProfileViewModel.snapshot?.profile.appearance ?? .system {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
