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

        do {
            container = try AppContainer(isStoredInMemoryOnly: isTesting)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            LearningRootView(
                learningJourneyViewModel: container.learningJourneyViewModel,
                learnerProfileViewModel: container.learnerProfileViewModel
            )
        }
    }
}
