import Foundation

/// Supplies the display order of a question's answers. Injected like
/// `LearningClock` so the order is reproducible in tests and fixtures.
@MainActor
protocol ChoiceOrderRandomizing {
    func order(_ ids: [String], seed: String) -> [String]
}

/// Deterministic order derived from the seed. The same seed always produces
/// the same order, on every platform and across launches, so an order can be
/// recomputed from stored evidence. `Array.shuffled()` is deliberately not
/// used: it is neither reproducible nor testable.
@MainActor
struct SeededChoiceOrderRandomizer: ChoiceOrderRandomizing {
    init() {}

    func order(_ ids: [String], seed: String) -> [String] {
        guard ids.count > 1 else { return ids }
        var generator = SplitMix64(seed: Self.seedValue(for: seed))
        var ordered = ids
        // Fisher-Yates, so every input appears exactly once.
        for index in stride(from: ordered.count - 1, to: 0, by: -1) {
            let swapIndex = Int(generator.next(upperBound: UInt64(index + 1)))
            ordered.swapAt(index, swapIndex)
        }
        return ordered
    }

    /// FNV-1a: `String.hashValue` is randomized per process and cannot seed a
    /// reproducible order.
    static func seedValue(for seed: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in Array(seed.utf8) {
            hash ^= UInt64(byte)
            hash &*= 0x100_0000_01b3
        }
        return hash
    }
}

/// The authored order, unchanged. Used by deterministic UI fixtures.
@MainActor
struct IdentityChoiceOrder: ChoiceOrderRandomizing {
    init() {}

    func order(_ ids: [String], seed: String) -> [String] { ids }
}

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Rejection sampling keeps the distribution uniform.
    mutating func next(upperBound: UInt64) -> UInt64 {
        precondition(upperBound > 0)
        let limit = UInt64.max - (UInt64.max % upperBound)
        var value = next()
        while value >= limit {
            value = next()
        }
        return value % upperBound
    }
}
