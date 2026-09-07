//
//  Swift_LearnApp.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import SwiftUI

@main
struct Swift_LearnApp: App {
    private let container: AppContainer

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
        let seedsBossFixture = processInfo.arguments.contains(
            "--ui-testing-boss-fixture"
        )
        let seedsProjectFixture = processInfo.arguments.contains(
            "--ui-testing-project-fixture"
        )
        let failsFirstBossCompletionSave = processInfo.arguments.contains(
            "--ui-testing-fail-first-boss-completion-save"
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
                seedsBossFixture: seedsBossFixture,
                seedsProjectFixture: seedsProjectFixture,
                failsFirstBossCompletionSave: failsFirstBossCompletionSave,
                clock: clock,
                idGenerator: idGenerator
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            LearningRootView(
                introViewModel: container.introViewModel,
                learningJourneyViewModel: container.learningJourneyViewModel,
                bossChallengeViewModel: container.bossChallengeViewModel,
                projectViewModel: container.projectViewModel,
                learnerProfileViewModel: container.learnerProfileViewModel,
                reviewQueueViewModel: container.reviewQueueViewModel,
                mistakeNotebookViewModel: container.mistakeNotebookViewModel
            )
        }
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
