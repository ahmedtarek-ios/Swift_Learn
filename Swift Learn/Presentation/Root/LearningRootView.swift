//
//  LearningRootView.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 23/08/2026.
//

import SwiftUI

struct LearningRootView: View {
    @State private var introViewModel: IntroViewModel
    private let learningJourneyViewModel: LearningJourneyViewModel
    @State private var learnerProfileViewModel: LearnerProfileViewModel
    private let reviewQueueViewModel: ReviewQueueViewModel
    private let mistakeNotebookViewModel: MistakeNotebookViewModel

    init(
        introViewModel: IntroViewModel,
        learningJourneyViewModel: LearningJourneyViewModel,
        learnerProfileViewModel: LearnerProfileViewModel,
        reviewQueueViewModel: ReviewQueueViewModel,
        mistakeNotebookViewModel: MistakeNotebookViewModel
    ) {
        _introViewModel = State(initialValue: introViewModel)
        self.learningJourneyViewModel = learningJourneyViewModel
        _learnerProfileViewModel = State(initialValue: learnerProfileViewModel)
        self.reviewQueueViewModel = reviewQueueViewModel
        self.mistakeNotebookViewModel = mistakeNotebookViewModel
    }

    var body: some View {
        rootContent
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

    @ViewBuilder
    private var rootContent: some View {
        if introViewModel.isPresented {
            IntroView(viewModel: introViewModel)
                .transition(.opacity)
        } else {
            learningTabs
                .transition(.opacity)
        }
    }

    private var learningTabs: some View {
        TabView {
            LearningJourneyView(
                viewModel: learningJourneyViewModel,
                reviewViewModel: reviewQueueViewModel,
                mistakeViewModel: mistakeNotebookViewModel
            )
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
