import Foundation
@preconcurrency import WatchConnectivity

@MainActor
final class WatchConnectivityLearningSnapshotRepository: NSObject,
    WatchLearningSnapshotRepository,
    WCSessionDelegate {
    private static let cacheKey = "swiftLearn.watch.snapshot.cache.v1"

    private let session: WCSession
    private let defaults: UserDefaults
    private var continuation:
        AsyncThrowingStream<WatchLearningSnapshot?, any Error>.Continuation?

    init(
        session: WCSession = .default,
        defaults: UserDefaults = .standard
    ) {
        self.session = session
        self.defaults = defaults
        super.init()
        session.delegate = self
    }

    func snapshots() -> AsyncThrowingStream<WatchLearningSnapshot?, any Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation

            guard WCSession.isSupported() else {
                continuation.finish(
                    throwing: WatchLearningSnapshotRepositoryError.unsupported
                )
                return
            }

            do {
                if let current = try currentSnapshot() {
                    continuation.yield(current)
                } else {
                    continuation.yield(nil)
                }
                session.activate()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        let errorDescription = error?.localizedDescription
        Task { @MainActor [weak self] in
            guard let self, let errorDescription else { return }
            continuation?.finish(
                throwing: WatchLearningSnapshotRepositoryError.activationFailed(
                    errorDescription
                )
            )
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let payload = applicationContext[
            WatchLearningSnapshotWireFormat.payloadKey
        ] as? Data else {
            return
        }

        Task { @MainActor [weak self, payload] in
            self?.receive(payload)
        }
    }

    private func currentSnapshot() throws -> WatchLearningSnapshot? {
        if let payload = session.applicationContext[
            WatchLearningSnapshotWireFormat.payloadKey
        ] as? Data {
            return try decodeAndCache(payload)
        }
        guard let payload = defaults.data(forKey: Self.cacheKey) else {
            return nil
        }
        return try WatchLearningSnapshotWireFormat.decode(payload)
    }

    private func receive(_ payload: Data) {
        do {
            continuation?.yield(try decodeAndCache(payload))
        } catch {
            continuation?.finish(throwing: error)
        }
    }

    private func decodeAndCache(_ payload: Data) throws -> WatchLearningSnapshot {
        let snapshot = try WatchLearningSnapshotWireFormat.decode(payload)
        defaults.set(payload, forKey: Self.cacheKey)
        return snapshot
    }
}

enum WatchLearningSnapshotRepositoryError: LocalizedError, Equatable {
    case unsupported
    case activationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupported:
            "Apple Watch sync is unavailable."
        case let .activationFailed(message):
            "Apple Watch sync could not start: \(message)"
        }
    }
}
