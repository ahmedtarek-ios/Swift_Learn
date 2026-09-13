import Foundation

enum LearningSyncWireFormat {
    nonisolated static let eventPayloadKey = "swiftLearn.watch.sync.event.v1"

    static func encode(_ event: LearningSyncEvent) throws -> Data {
        try JSONEncoder().encode(event)
    }

    static func decodeEvent(_ data: Data) throws -> LearningSyncEvent {
        let event = try JSONDecoder().decode(LearningSyncEvent.self, from: data)
        guard event.schemaVersion == LearningSyncEvent.currentSchemaVersion else {
            throw LearningSyncDomainError.unsupportedEventSchema(event.schemaVersion)
        }
        return event
    }
}
