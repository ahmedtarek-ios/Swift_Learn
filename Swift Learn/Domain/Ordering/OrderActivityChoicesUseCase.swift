import Foundation

/// Orders a question's answers for display. Call it once when a question
/// becomes current and keep the result: ordering inside a SwiftUI `body`
/// reorders the answers on every redraw.
@MainActor
struct OrderActivityChoicesUseCase {
    private let randomizer: any ChoiceOrderRandomizing

    init(randomizer: any ChoiceOrderRandomizing) {
        self.randomizer = randomizer
    }

    /// The seed pairs a question with its attempt number, so a retry reshuffles
    /// while a redraw does not.
    static func seed(questionID: String, attemptNumber: Int) -> String {
        "\(questionID)#\(attemptNumber)"
    }

    func execute(_ choices: [LearningChoice], seed: String) -> [LearningChoice] {
        reorder(choices, ids: choices.map(\.id), seed: seed) { $0.id }
    }

    func execute(
        _ choices: [SupplementalPracticeChoice],
        seed: String
    ) -> [SupplementalPracticeChoice] {
        reorder(choices, ids: choices.map(\.id), seed: seed) { $0.id }
    }

    func execute(_ choices: [GitCommandChoice], seed: String) -> [GitCommandChoice] {
        reorder(choices, ids: choices.map(\.id), seed: seed) { $0.id }
    }

    func execute(
        _ choices: [WatchReviewChoiceSnapshot],
        seed: String
    ) -> [WatchReviewChoiceSnapshot] {
        reorder(choices, ids: choices.map(\.id), seed: seed) { $0.id }
    }

    private func reorder<Choice>(
        _ choices: [Choice],
        ids: [String],
        seed: String,
        id: (Choice) -> String
    ) -> [Choice] {
        guard choices.count > 1 else { return choices }
        let orderedIDs = randomizer.order(ids, seed: seed)
        let byID = Dictionary(
            choices.map { (id($0), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let ordered = orderedIDs.compactMap { byID[$0] }
        // A randomizer that drops or invents an ID must not lose an answer.
        return ordered.count == choices.count ? ordered : choices
    }
}
