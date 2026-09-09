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

    init(session: WCSession = .default) {
        self.session = session
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
