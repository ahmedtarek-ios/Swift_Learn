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
    private let bossChallengeViewModel: BossChallengeViewModel
    private let projectViewModel: LearningProjectViewModel
    @State private var learnerProfileViewModel: LearnerProfileViewModel
    private let reviewQueueViewModel: ReviewQueueViewModel
    private let mistakeNotebookViewModel: MistakeNotebookViewModel
    private let learningDiscoveryViewModel: LearningDiscoveryViewModel
    private let supplementalTracksViewModel: SupplementalTracksViewModel
    private let forcesRightToLeftLayout: Bool

    init(
        introViewModel: IntroViewModel,
        learningJourneyViewModel: LearningJourneyViewModel,
        bossChallengeViewModel: BossChallengeViewModel,
        projectViewModel: LearningProjectViewModel,
        learnerProfileViewModel: LearnerProfileViewModel,
        reviewQueueViewModel: ReviewQueueViewModel,
        mistakeNotebookViewModel: MistakeNotebookViewModel,
        learningDiscoveryViewModel: LearningDiscoveryViewModel,
        supplementalTracksViewModel: SupplementalTracksViewModel,
        forcesRightToLeftLayout: Bool = false
    ) {
        _introViewModel = State(initialValue: introViewModel)
        self.learningJourneyViewModel = learningJourneyViewModel
        self.bossChallengeViewModel = bossChallengeViewModel
        self.projectViewModel = projectViewModel
        _learnerProfileViewModel = State(initialValue: learnerProfileViewModel)
        self.reviewQueueViewModel = reviewQueueViewModel
        self.mistakeNotebookViewModel = mistakeNotebookViewModel
        self.learningDiscoveryViewModel = learningDiscoveryViewModel
        self.supplementalTracksViewModel = supplementalTracksViewModel
        self.forcesRightToLeftLayout = forcesRightToLeftLayout
    }

    var body: some View {
        configuredRootContent
    }

    @ViewBuilder
    private var configuredRootContent: some View {
        if forcesRightToLeftLayout {
            rootContent.environment(\.layoutDirection, .rightToLeft)
        } else {
            rootContent
        }
    }

    private var rootContent: some View {
        content
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
            .onChange(of: learnerProfileViewModel.resetRevision) {
                learningJourneyViewModel.reloadAtJourneyRoot()
                reviewQueueViewModel.load()
                mistakeNotebookViewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
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
                bossChallengeViewModel: bossChallengeViewModel,
                projectViewModel: projectViewModel,
                reviewViewModel: reviewQueueViewModel,
                mistakeViewModel: mistakeNotebookViewModel,
                discoveryViewModel: learningDiscoveryViewModel,
                supplementalViewModel: supplementalTracksViewModel
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
