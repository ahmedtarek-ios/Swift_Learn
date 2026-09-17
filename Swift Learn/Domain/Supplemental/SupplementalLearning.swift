import Foundation

struct SupplementalSourceLock: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let references: [String]
}

struct SupplementalLesson: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let objective: String
    let keyPoints: [String]
    let practice: SupplementalPractice
    let lab: SupplementalAuthoredLab?

    init(
        id: String,
        title: String,
        objective: String,
        keyPoints: [String],
        practice: SupplementalPractice,
        lab: SupplementalAuthoredLab? = nil
    ) {
        self.id = id
        self.title = title
        self.objective = objective
        self.keyPoints = keyPoints
        self.practice = practice
        self.lab = lab
    }
}

struct SupplementalAuthoredLab: Equatable, Sendable {
    let activity: LearningActivity
    let correctFeedback: String
    let incorrectFeedback: String
}

struct SupplementalPracticeChoice: Identifiable, Equatable, Sendable {
    let id: String
    let text: String
}

struct SupplementalPractice: Equatable, Sendable {
    let prompt: String
    let choices: [SupplementalPracticeChoice]
    let correctChoiceID: String
    let correctFeedback: String
    let incorrectFeedback: String
}

enum SupplementalPracticeResult: Equatable, Sendable {
    case correct(String)
    case incorrect(String)
}

struct SupplementalTrack: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let source: SupplementalSourceLock
    let lessons: [SupplementalLesson]
}

@MainActor
protocol SupplementalTrackRepository {
    func loadTracks() throws -> [SupplementalTrack]
}

enum SupplementalLearningError: LocalizedError, Equatable {
    case invalidTrackID(String)
    case invalidLessonID(String)
    case duplicateTrackID(String)
    case duplicateLessonID(String)
    case missingSourceReference(String)
    case emptyTrack(String)
    case invalidPractice(String)
    case invalidAuthoredLab(String)
    case invalidActivityResponse(String)

    var errorDescription: String? {
        switch self {
        case let .invalidTrackID(id):
            "Supplemental track identifier must start with supplemental: \(id)."
        case let .invalidLessonID(id):
            "Supplemental lesson identifier must start with supplemental: \(id)."
        case let .duplicateTrackID(id):
            "Duplicate supplemental track identifier: \(id)."
        case let .duplicateLessonID(id):
            "Duplicate supplemental lesson identifier: \(id)."
        case let .missingSourceReference(id):
            "Supplemental source has no reference: \(id)."
        case let .emptyTrack(id):
            "Supplemental track has no lessons: \(id)."
        case let .invalidPractice(id):
            "Supplemental lesson has an invalid practice activity: \(id)."
        case let .invalidAuthoredLab(id):
            "Supplemental lesson has an invalid authored lab: \(id)."
        case let .invalidActivityResponse(id):
            "Complete the authored lab with a valid answer: \(id)."
        }
    }
}

@MainActor
struct LoadSupplementalTracksUseCase {
    private let repository: any SupplementalTrackRepository

    init(repository: any SupplementalTrackRepository) {
        self.repository = repository
    }

    func execute() throws -> [SupplementalTrack] {
        let tracks = try repository.loadTracks()
        var trackIDs = Set<String>()
        var lessonIDs = Set<String>()

        for track in tracks {
            guard track.id.hasPrefix("supplemental.") else {
                throw SupplementalLearningError.invalidTrackID(track.id)
            }
            guard trackIDs.insert(track.id).inserted else {
                throw SupplementalLearningError.duplicateTrackID(track.id)
            }
            guard !track.source.references.isEmpty else {
                throw SupplementalLearningError.missingSourceReference(track.source.id)
            }
            guard !track.lessons.isEmpty else {
                throw SupplementalLearningError.emptyTrack(track.id)
            }
            for lesson in track.lessons {
                guard lesson.id.hasPrefix("supplemental.") else {
                    throw SupplementalLearningError.invalidLessonID(lesson.id)
                }
                guard lessonIDs.insert(lesson.id).inserted else {
                    throw SupplementalLearningError.duplicateLessonID(lesson.id)
                }
                let choiceIDs = lesson.practice.choices.map(\.id)
                guard choiceIDs.count >= 2,
                      Set(choiceIDs).count == choiceIDs.count,
                      choiceIDs.contains(lesson.practice.correctChoiceID) else {
                    throw SupplementalLearningError.invalidPractice(lesson.id)
                }
                if let lab = lesson.lab {
                    guard lab.activity.schemaVersion == 1,
                          lab.activity.prompt.isEmpty == false,
                          lab.correctFeedback.isEmpty == false,
                          lab.incorrectFeedback.isEmpty == false,
                          lab.isWellFormed else {
                        throw SupplementalLearningError.invalidAuthoredLab(lesson.id)
                    }
                }
            }
        }
        return tracks
    }
}

struct EvaluateSupplementalPracticeUseCase {
    func execute(
        choiceID: String,
        lesson: SupplementalLesson
    ) -> SupplementalPracticeResult {
        choiceID == lesson.practice.correctChoiceID
            ? .correct(lesson.practice.correctFeedback)
            : .incorrect(lesson.practice.incorrectFeedback)
    }
}

struct EvaluateSupplementalAuthoredLabUseCase {
    func execute(
        response: LearningActivityResponse,
        lesson: SupplementalLesson
    ) throws -> SupplementalPracticeResult {
        guard let lab = lesson.lab else {
            throw SupplementalLearningError.invalidAuthoredLab(lesson.id)
        }
        guard lab.activity.accepts(response) else {
            throw SupplementalLearningError.invalidActivityResponse(lesson.id)
        }
        return lab.activity.isCorrect(response)
            ? .correct(lab.correctFeedback)
            : .incorrect(lab.incorrectFeedback)
    }
}

private extension SupplementalAuthoredLab {
    var isWellFormed: Bool {
        switch activity {
        case let .unitTestAuthoring(test):
            test.framework.isEmpty == false
                && test.target.isEmpty == false
                && test.requiredAssertion.isEmpty == false
                && test.expectedOutcome.isEmpty == false
                && test.composition.isWellFormed
        case let .uiTestAuthoring(test):
            test.framework.isEmpty == false
                && test.entryIdentifier.isEmpty == false
                && test.resultIdentifier.isEmpty == false
                && test.expectedOutcome.isEmpty == false
                && test.composition.isWellFormed
        case let .architectureClassification(classification):
            classification.items.count >= 2
                && Set(classification.items.map(\.id)).count
                    == classification.items.count
                && classification.items.allSatisfy {
                    $0.id.isEmpty == false && $0.responsibility.isEmpty == false
                }
        default:
            false
        }
    }
}
