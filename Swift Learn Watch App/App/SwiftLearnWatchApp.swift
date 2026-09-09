import SwiftUI

@main
struct SwiftLearnWatchApp: App {
    private let container = WatchAppContainer()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(viewModel: container.homeViewModel)
        }
    }
}
