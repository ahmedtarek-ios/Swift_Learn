import Foundation

/// App-group storage shared by the Watch app and its widgets. The Watch app
/// writes the latest synchronized snapshot; widgets only read it.
nonisolated enum WatchSharedStore {
    static let appGroupID = "group.com.ata.Swift-Learn"
    static let snapshotCacheKey = "swiftLearn.watch.snapshot.cache.v1"

    static func defaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func loadSnapshot(
        from defaults: UserDefaults = WatchSharedStore.defaults()
    ) -> WatchLearningSnapshot? {
        guard let payload = defaults.data(forKey: snapshotCacheKey) else {
            return nil
        }
        return try? WatchLearningSnapshotWireFormat.decode(payload)
    }
}
