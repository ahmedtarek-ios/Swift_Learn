import Foundation

enum WatchLearningSnapshotWireFormat {
    nonisolated static let payloadKey = "swiftLearn.watch.snapshot.v1"
    nonisolated static let refreshRequestKey = "swiftLearn.watch.refresh.v1"

    static func encode(_ snapshot: WatchLearningSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    static func decode(_ data: Data) throws -> WatchLearningSnapshot {
        let snapshot = try JSONDecoder().decode(WatchLearningSnapshot.self, from: data)
        guard (1...WatchLearningSnapshot.currentSchemaVersion).contains(
            snapshot.schemaVersion
        ) else {
            throw WatchLearningSnapshotWireError.unsupportedSchema(
                snapshot.schemaVersion
            )
        }
        return snapshot
    }
}

enum WatchLearningSnapshotWireError: LocalizedError, Equatable {
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchema(version):
            "Unsupported Apple Watch snapshot schema: \(version)."
        }
    }
}
