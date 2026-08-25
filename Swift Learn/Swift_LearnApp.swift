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
        let clock: any LearningClock = seedsReviewFixture
            ? UITestReviewClock()
            : SystemLearningClock()

        do {
            container = try AppContainer(
                isStoredInMemoryOnly: isTesting && !usesPersistentUITestStore,
                showsIntro: showsIntro,
                storageName: usesPersistentUITestStore ? "SwiftLearnUITests" : nil,
                resetsStoredData: processInfo.arguments.contains(
                    "--reset-ui-testing-data"
                ),
                seedsReviewFixture: seedsReviewFixture,
                clock: clock
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
