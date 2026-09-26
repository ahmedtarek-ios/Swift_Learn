import Foundation
import Testing
@testable import Swift_Learn

@MainActor
struct ChoiceOrderTests {
    @Test
    func sameSeedProducesTheSameOrderTwice() {
        let randomizer = SeededChoiceOrderRandomizer()
        let ids = ["a", "b", "c", "d", "e"]

        let first = randomizer.order(ids, seed: "swift.bindings.constants#1")
        let second = randomizer.order(ids, seed: "swift.bindings.constants#1")

        #expect(first == second)
    }

    @Test
    func aRetryReshufflesTheSameQuestion() {
        let randomizer = SeededChoiceOrderRandomizer()
        let ids = ["a", "b", "c", "d", "e", "f"]
        let lessonID = "swift.bindings.constants"

        let firstAttempt = randomizer.order(
            ids,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: lessonID,
                attemptNumber: 1
            )
        )
        let secondAttempt = randomizer.order(
            ids,
            seed: OrderActivityChoicesUseCase.seed(
                questionID: lessonID,
                attemptNumber: 2
            )
        )

        #expect(firstAttempt != secondAttempt)
        #expect(Set(firstAttempt) == Set(ids))
        #expect(Set(secondAttempt) == Set(ids))
    }

    @Test
    func everyAnswerAppearsExactlyOnceAcrossManySeeds() {
        let randomizer = SeededChoiceOrderRandomizer()
        let ids = ["a", "b", "c", "d"]

        for attempt in 1...50 {
            let ordered = randomizer.order(ids, seed: "lesson#\(attempt)")
            #expect(ordered.count == ids.count)
            #expect(Set(ordered) == Set(ids))
        }
    }

    @Test
    func everyPositionIsReachableSoNoAnswerIsPinned() {
        let randomizer = SeededChoiceOrderRandomizer()
        let ids = ["a", "b", "c", "d"]
        var positionsOfA: Set<Int> = []

        for attempt in 1...200 {
            let ordered = randomizer.order(ids, seed: "lesson#\(attempt)")
            if let index = ordered.firstIndex(of: "a") {
                positionsOfA.insert(index)
            }
        }

        #expect(positionsOfA == [0, 1, 2, 3])
    }

    @Test
    func shortInputsAreReturnedUnchanged() {
        let randomizer = SeededChoiceOrderRandomizer()

        #expect(randomizer.order([], seed: "lesson#1").isEmpty)
        #expect(randomizer.order(["only"], seed: "lesson#1") == ["only"])
        #expect(Set(randomizer.order(["a", "b"], seed: "lesson#1")) == ["a", "b"])
    }

    @Test
    func identityOrderKeepsTheAuthoredOrder() {
        let ids = ["a", "b", "c"]

        #expect(IdentityChoiceOrder().order(ids, seed: "lesson#9") == ids)
    }

    @Test
    func useCaseReordersLearningChoicesWithoutLosingAny() {
        let choices = [
            LearningChoice(id: "let", code: "let"),
            LearningChoice(id: "var", code: "var"),
            LearningChoice(id: "inout", code: "inout"),
            LearningChoice(id: "static", code: "static")
        ]
        let useCase = OrderActivityChoicesUseCase(
            randomizer: SeededChoiceOrderRandomizer()
        )

        let ordered = useCase.execute(choices, seed: "lesson#3")

        #expect(ordered.count == choices.count)
        #expect(Set(ordered.map(\.id)) == Set(choices.map(\.id)))
        #expect(ordered.map(\.id) != choices.map(\.id))
    }

    @Test
    func aRandomizerThatLosesAnAnswerFallsBackToTheAuthoredOrder() {
        let choices = [
            LearningChoice(id: "let", code: "let"),
            LearningChoice(id: "var", code: "var"),
            LearningChoice(id: "inout", code: "inout")
        ]
        let useCase = OrderActivityChoicesUseCase(randomizer: DroppingRandomizer())

        let ordered = useCase.execute(choices, seed: "lesson#1")

        #expect(ordered.map(\.id) == choices.map(\.id))
    }
}

@MainActor
private struct DroppingRandomizer: ChoiceOrderRandomizing {
    func order(_ ids: [String], seed: String) -> [String] {
        Array(ids.dropLast())
    }
}
