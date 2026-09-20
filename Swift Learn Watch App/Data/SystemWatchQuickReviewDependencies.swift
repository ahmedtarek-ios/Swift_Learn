import Foundation

@MainActor
struct SystemWatchQuickReviewClock: WatchQuickReviewClock {
    var now: Date { .now }
}

@MainActor
struct SystemWatchQuickReviewIDGenerator: WatchQuickReviewIDGenerating {
    func next() -> UUID { UUID() }
}

@MainActor
final class UserDefaultsWatchDeviceIDProvider: WatchDeviceIDProviding {
    private static let key = "swiftLearn.watch.device.id.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func deviceID() -> String {
        if let identifier = defaults.string(forKey: Self.key),
           identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                == false {
            return identifier
        }
        let identifier = UUID().uuidString
        defaults.set(identifier, forKey: Self.key)
        return identifier
    }
}
