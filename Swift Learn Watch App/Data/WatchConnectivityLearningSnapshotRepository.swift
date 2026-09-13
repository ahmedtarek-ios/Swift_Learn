import Foundation
@preconcurrency import WatchConnectivity

@MainActor
final class WatchConnectivityLearningSnapshotRepository: NSObject,
    WatchLearningSnapshotRepository,
    WatchLearningEventSubmitting,
    WCSessionDelegate {
    private static let cacheKey = "swiftLearn.watch.snapshot.cache.v1"

    private let session: WCSession
    private let defaults: UserDefaults
    private let syncEventQueue: any LearningSyncEventQueueRepository
    private let syncGeneration: any LearningSyncResetGenerationAdopting
    private var inFlightEventIDs: Set<UUID> = []
    private var continuation:
        AsyncThrowingStream<WatchLearningSnapshot?, any Error>.Continuation?

    init(
        session: WCSession = .default,
        defaults: UserDefaults = .standard,
        syncEventQueue: any LearningSyncEventQueueRepository,
        syncGeneration: any LearningSyncResetGenerationAdopting
    ) {
        self.session = session
        self.defaults = defaults
        self.syncEventQueue = syncEventQueue
        self.syncGeneration = syncGeneration
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

    func submit(_ event: LearningSyncEvent) throws {
        try syncEventQueue.enqueue(event)
        guard WCSession.isSupported() else {
            throw WatchLearningSnapshotRepositoryError.unsupported
        }
        if session.activationState == .notActivated {
            session.activate()
        }
        try flushPendingEvents()
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
        guard errorDescription == nil, activationState == .activated else { return }
        Task { @MainActor [weak self] in
            do {
                try self?.flushPendingEvents()
                self?.requestImmediateRefresh()
            } catch {
                self?.continuation?.finish(throwing: error)
            }
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

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor [weak self] in
            self?.requestImmediateRefresh()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didFinish userInfoTransfer: WCSessionUserInfoTransfer,
        error: (any Error)?
    ) {
        guard let payload = userInfoTransfer.userInfo[
            LearningSyncWireFormat.eventPayloadKey
        ] as? Data else {
            return
        }
        Task { @MainActor [weak self, payload] in
            guard let self,
                  let event = try? LearningSyncWireFormat.decodeEvent(payload) else {
                return
            }
            if error != nil {
                inFlightEventIDs.remove(event.id)
            }
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
            let snapshot = try decodeAndCache(payload)
            continuation?.yield(snapshot)
        } catch {
            continuation?.finish(throwing: error)
        }
    }

    private func decodeAndCache(_ payload: Data) throws -> WatchLearningSnapshot {
        let snapshot = try WatchLearningSnapshotWireFormat.decode(payload)
        try syncGeneration.adoptResetGeneration(snapshot.resetGeneration)
        try syncEventQueue.removePendingEvents(ids: snapshot.acknowledgedEventIDs)
        inFlightEventIDs.subtract(snapshot.acknowledgedEventIDs)
        defaults.set(payload, forKey: Self.cacheKey)
        try flushPendingEvents()
        return snapshot
    }

    private func flushPendingEvents() throws {
        guard session.activationState == .activated else { return }
        let outstandingIDs = Set<UUID>(session.outstandingUserInfoTransfers.compactMap {
            guard let payload = $0.userInfo[
                LearningSyncWireFormat.eventPayloadKey
            ] as? Data else { return nil }
            return try? LearningSyncWireFormat.decodeEvent(payload).id
        })
        inFlightEventIDs.formUnion(outstandingIDs)

        for event in try syncEventQueue.loadPendingEvents()
            where inFlightEventIDs.contains(event.id) == false {
            let payload = try LearningSyncWireFormat.encode(event)
            inFlightEventIDs.insert(event.id)
            session.transferUserInfo([
                LearningSyncWireFormat.eventPayloadKey: payload
            ])
        }
    }

    private func requestImmediateRefresh() {
        guard session.activationState == .activated, session.isReachable else {
            return
        }
        session.sendMessage(
            [WatchLearningSnapshotWireFormat.refreshRequestKey: true],
            replyHandler: { [weak self] reply in
                guard let payload = reply[
                    WatchLearningSnapshotWireFormat.payloadKey
                ] as? Data else { return }
                Task { @MainActor [weak self, payload] in
                    self?.receive(payload)
                }
            },
            errorHandler: nil
        )
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
