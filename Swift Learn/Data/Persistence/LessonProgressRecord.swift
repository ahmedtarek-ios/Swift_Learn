//
//  LessonProgressRecord.swift
//  Swift Learn
//
//  Created by Ahmed Tarek on 16/08/2026.
//

import Foundation
import SwiftData

@Model
final class LessonProgressRecord {
    @Attribute(.unique) var lessonID: String
    var completedAt: Date

    init(lessonID: String, completedAt: Date) {
        self.lessonID = lessonID
        self.completedAt = completedAt
    }
}
