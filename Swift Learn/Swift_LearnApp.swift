//
//  Swift_LearnApp.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import SwiftUI

@main
struct Swift_LearnApp: App {
#if os(iOS)
    @Environment(\.scenePhase) private var scenePhase
#endif
    private let container: AppContainer
    private let forcesRightToLeftLayout: Bool

    init() {
        let processInfo = ProcessInfo.processInfo
        let isTesting = processInfo.arguments.contains("--ui-testing")
            || processInfo.environment["XCTestConfigurationFilePath"] != nil
        let usesPersistentUITestStore = processInfo.arguments.contains(
            "--ui-testing-persistent"
        )
        let showsIntro = !processInfo.arguments.contains("--skip-intro")
        let seedsReviewFixture = processInfo.arguments.contains(
            "--ui-testing-review-fixture"
        )
        let seedsActivityFixture = processInfo.arguments.contains(
            "--ui-testing-activity-fixture"
        )
        let seedsCodeOrderingFixture = processInfo.arguments.contains(
            "--ui-testing-code-ordering-fixture"
        )
        let activityFixtureKind = processInfo.arguments.first {
            $0.hasPrefix("--ui-testing-activity-kind=")
        }?.split(separator: "=", maxSplits: 1).last.flatMap {
            LearningActivityKind(rawValue: String($0))
        }
        let seedsBossFixture = processInfo.arguments.contains(
            "--ui-testing-boss-fixture"
        )
        let seedsLevelCompletionFixture = processInfo.arguments.contains(
            "--ui-testing-level-completion-fixture"
        )
        let seedsProjectFixture = processInfo.arguments.contains(
            "--ui-testing-project-fixture"
        )
        let seedsGitFinalFixture = processInfo.arguments.contains(
            "--ui-testing-git-final-fixture"
        )
        let failsGitReset = processInfo.arguments.contains(
            "--ui-testing-fail-git-reset"
        )
        let failsFirstBossCompletionSave = processInfo.arguments.contains(
            "--ui-testing-fail-first-boss-completion-save"
        )
        let initialDiscoveryQuery = processInfo.arguments.first {
            $0.hasPrefix("--ui-testing-discovery-query=")
        }?.split(separator: "=", maxSplits: 1).last.map(String.init) ?? ""
        // UI tests that press Right N times to reach a known answer need the
        // authored order; everything else sees the shuffled order.
        let usesFixedChoiceOrder = processInfo.arguments.contains(
            "--ui-testing-fixed-choice-order"
        )
        forcesRightToLeftLayout = processInfo.arguments.contains(
            "--ui-testing-rtl"
        )
        let clock: any LearningClock = seedsReviewFixture
            ? UITestReviewClock()
            : SystemLearningClock()
        let idGenerator: any LearningAttemptIDGenerating = seedsReviewFixture
            ? UITestLearningAttemptIDGenerator()
            : SystemLearningAttemptIDGenerator()

        do {
            container = try AppContainer(
                isStoredInMemoryOnly: isTesting && !usesPersistentUITestStore,
                showsIntro: showsIntro,
                storageName: usesPersistentUITestStore ? "SwiftLearnUITests" : nil,
                resetsStoredData: processInfo.arguments.contains(
                    "--reset-ui-testing-data"
                ),
                seedsReviewFixture: seedsReviewFixture,
                seedsActivityFixture: seedsActivityFixture,
                seedsCodeOrderingFixture: seedsCodeOrderingFixture,
                activityFixtureKind: activityFixtureKind,
                seedsBossFixture: seedsBossFixture,
                seedsLevelCompletionFixture: seedsLevelCompletionFixture,
                seedsProjectFixture: seedsProjectFixture,
                seedsGitFinalFixture: seedsGitFinalFixture,
                failsGitReset: failsGitReset,
                failsFirstBossCompletionSave: failsFirstBossCompletionSave,
                initialDiscoveryQuery: initialDiscoveryQuery,
                usesFixedChoiceOrder: usesFixedChoiceOrder,
                clock: clock,
                idGenerator: idGenerator
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
#if os(iOS)
            learningRootView
                .task {
                    container.syncAppleWatch()
                }
                .onChange(of: scenePhase) {
                    guard scenePhase == .active else { return }
                    container.syncAppleWatch()
                }
#else
            learningRootView
#endif
        }
    }

    private var learningRootView: LearningRootView {
        LearningRootView(
            introViewModel: container.introViewModel,
            learningJourneyViewModel: container.learningJourneyViewModel,
            bossChallengeViewModel: container.bossChallengeViewModel,
            projectViewModel: container.projectViewModel,
            learnerProfileViewModel: container.learnerProfileViewModel,
            reviewQueueViewModel: container.reviewQueueViewModel,
            mistakeNotebookViewModel: container.mistakeNotebookViewModel,
            learningDiscoveryViewModel: container.learningDiscoveryViewModel,
            supplementalTracksViewModel: container.supplementalTracksViewModel,
            gitLearningViewModel: container.gitLearningViewModel,
            forcesRightToLeftLayout: forcesRightToLeftLayout
        )
    }
}

@MainActor
private struct UITestReviewClock: LearningClock {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
}

@MainActor
private final class UITestLearningAttemptIDGenerator: LearningAttemptIDGenerating {
    private var sequence: UInt64 = 1

    func next() -> UUID {
        defer { sequence += 1 }
        let suffix = String(format: "%012llx", sequence)
        return UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!
    }
}
