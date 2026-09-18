//
//  LearningSyncStateRecord.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 09/09/2026.
//

import Foundation
import SwiftData

@Model
final class LearningSyncStateRecord {
    @Attribute(.unique) var key: String
    var resetGeneration: Int

    init(key: String = "primary", resetGeneration: Int) {
        self.key = key
        self.resetGeneration = resetGeneration
    }
}

@Model
final class LearningSyncEventReceiptRecord {
    @Attribute(.unique) var eventID: UUID
    var resetGeneration: Int

    init(eventID: UUID, resetGeneration: Int) {
        self.eventID = eventID
        self.resetGeneration = resetGeneration
    }
}
