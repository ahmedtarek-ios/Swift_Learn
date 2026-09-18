//
//  WatchConnectivitySnapshotPublisher.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 09/09/2026.
//

#if os(iOS) && canImport(WatchConnectivity)
import Foundation
import OSLog
@preconcurrency import WatchConnectivity

@MainActor
final class WatchConnectivitySnapshotPublisher: NSObject,
    WatchLearningSnapshotPublishing,
    WCSessionDelegate {
    private let session: WCSession
    private let logger = Logger(
        subsystem: "com.ata.Swift-Learn",
        category: "AppleWatchSync"
    )
    private var pendingPayload: Data?
    private let receiveEvents:
        @MainActor ([LearningSyncEvent]) throws -> WatchLearningSnapshot?

    init(
        session: WCSession = .default,
        receiveEvents: @escaping @MainActor ([LearningSyncEvent]) throws
            -> WatchLearningSnapshot? = { _ in nil }
    ) {
        self.session = session
        self.receiveEvents = receiveEvents
        super.init()
        session.delegate = self
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.activate()
    }

    func publish(_ snapshot: WatchLearningSnapshot) throws {
        pendingPayload = try WatchLearningSnapshotWireFormat.encode(snapshot)
        try publishPendingPayloadIfPossible()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        let errorDescription = error?.localizedDescription
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let errorDescription {
                logger.error("Watch session activation failed: \(errorDescription, privacy: .public)")
                return
            }
            do {
                try publishPendingPayloadIfPossible()
            } catch {
                logger.error("Watch snapshot publish failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.session.activate()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        guard let payload = userInfo[LearningSyncWireFormat.eventPayloadKey] as? Data else {
            return
        }
        Task { @MainActor [weak self, payload] in
            guard let self else { return }
            do {
                let event = try LearningSyncWireFormat.decodeEvent(payload)
                if let snapshot = try receiveEvents([event]) {
                    try publish(snapshot)
                }
            } catch {
                logger.error(
                    "Watch learning event rejected: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[WatchLearningSnapshotWireFormat.refreshRequestKey] as? Bool
                == true else {
            replyHandler([:])
            return
        }
        guard let payload = session.applicationContext[
            WatchLearningSnapshotWireFormat.payloadKey
        ] as? Data else {
            replyHandler([:])
            return
        }
        replyHandler([WatchLearningSnapshotWireFormat.payloadKey: payload])
    }

    private func publishPendingPayloadIfPossible() throws {
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled,
              let pendingPayload else {
            return
        }
        try session.updateApplicationContext([
            WatchLearningSnapshotWireFormat.payloadKey: pendingPayload
        ])
        self.pendingPayload = nil
    }
}
#endif
