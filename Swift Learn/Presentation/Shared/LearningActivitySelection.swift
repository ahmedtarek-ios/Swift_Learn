//
//  LearningActivitySelection.swift
//  Swift Learn
//

struct LearningActivitySelection: Equatable {
    private(set) var choiceID: String?
    private(set) var orderedFragmentIDs: [String] = []
    private(set) var draftText = ""
    private(set) var selectedTokenIDs: [String] = []
    private(set) var selectedLayers: [String: ArchitectureLayer] = [:]

    mutating func selectChoice(_ id: String) {
        choiceID = id
    }

    mutating func appendFragment(_ id: String, for activity: LearningActivity) {
        guard case let .codeOrdering(ordering) = activity,
              ordering.fragments.contains(where: { $0.id == id }),
              !orderedFragmentIDs.contains(id) else { return }
        orderedFragmentIDs.append(id)
    }

    mutating func removeFragment(_ id: String) {
        orderedFragmentIDs.removeAll { $0 == id }
    }

    mutating func editText(_ text: String) {
        draftText = text
        selectedTokenIDs = []
    }

    mutating func appendToken(_ id: String, for activity: LearningActivity) {
        guard let editing = activity.textComposition,
              editing.tokens.contains(where: { $0.id == id }),
              selectedTokenIDs.contains(id) == false else { return }
        selectedTokenIDs.append(id)
        draftText = editing.text(selectedTokenIDs: selectedTokenIDs)
    }

    mutating func removeToken(_ id: String, for activity: LearningActivity) {
        guard let editing = activity.textComposition else { return }
        selectedTokenIDs.removeAll { $0 == id }
        draftText = editing.text(selectedTokenIDs: selectedTokenIDs)
    }

    mutating func selectLayer(
        _ layer: ArchitectureLayer,
        itemID: String,
        for activity: LearningActivity
    ) {
        guard case let .architectureClassification(classification) = activity,
              classification.items.contains(where: { $0.id == itemID }) else { return }
        selectedLayers[itemID] = layer
    }

    mutating func reset() {
        choiceID = nil
        orderedFragmentIDs = []
        draftText = ""
        selectedTokenIDs = []
        selectedLayers = [:]
    }

    func response(for activity: LearningActivity) -> LearningActivityResponse? {
        switch activity {
        case .missingCode, .outputPrediction, .diagnosticSelection, .codeRepair:
            return choiceID.map(LearningActivityResponse.choice)
        case let .codeOrdering(ordering):
            guard orderedFragmentIDs.count == ordering.fragments.count else {
                return nil
            }
            return .orderedFragments(orderedFragmentIDs)
        case .constrainedEditing, .unitTestAuthoring, .uiTestAuthoring:
            guard draftText.isEmpty == false else { return nil }
            return .text(draftText)
        case let .architectureClassification(classification):
            guard selectedLayers.count == classification.items.count else { return nil }
            return .classifications(selectedLayers)
        case .projectValidation:
            return nil // E4's submission use case supplies this response, not a draft editor.
        }
    }
}
