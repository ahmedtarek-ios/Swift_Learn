import Foundation

/// Identifies which learning track a record or question belongs to. Tracks are
/// isolated: progress, attempts, and reset never cross a track boundary.
enum LearningTrackID: String, CaseIterable, Codable, Sendable {
    case swift
    case git

    var title: String {
        switch self {
        case .swift: "Swift"
        case .git: "Git"
        }
    }
}
