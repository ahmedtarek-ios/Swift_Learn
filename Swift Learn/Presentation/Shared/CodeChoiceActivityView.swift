//
//  CodeChoiceActivityView.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import SwiftUI

struct LearningActivityRenderer: View {
    let activity: LearningActivity
    let selectedChoiceID: String?
    let codeIdentifier: String
    let choiceIdentifierPrefix: String
    let selectChoice: (String) -> Void
    let reduceMotion: Bool
    let selectedFragmentIDs: [String]
    let selectFragment: (String) -> Void
    let removeFragment: (String) -> Void
    let draftText: String
    let selectedTokenIDs: [String]
    let editText: (String) -> Void
    let selectToken: (String) -> Void
    let removeToken: (String) -> Void
    let resetSelection: () -> Void
    let selectedLayers: [String: ArchitectureLayer]
    let selectLayer: (String, ArchitectureLayer) -> Void

    init(
        activity: LearningActivity,
        selectedChoiceID: String?,
        codeIdentifier: String,
        choiceIdentifierPrefix: String,
        selectChoice: @escaping (String) -> Void,
        reduceMotion: Bool,
        selectedFragmentIDs: [String] = [],
        selectFragment: @escaping (String) -> Void = { _ in },
        removeFragment: @escaping (String) -> Void = { _ in },
        draftText: String = "",
        selectedTokenIDs: [String] = [],
        editText: @escaping (String) -> Void = { _ in },
        selectToken: @escaping (String) -> Void = { _ in },
        removeToken: @escaping (String) -> Void = { _ in },
        resetSelection: @escaping () -> Void = {},
        selectedLayers: [String: ArchitectureLayer] = [:],
        selectLayer: @escaping (String, ArchitectureLayer) -> Void = { _, _ in }
    ) {
        self.activity = activity
        self.selectedChoiceID = selectedChoiceID
        self.codeIdentifier = codeIdentifier
        self.choiceIdentifierPrefix = choiceIdentifierPrefix
        self.selectChoice = selectChoice
        self.reduceMotion = reduceMotion
        self.selectedFragmentIDs = selectedFragmentIDs
        self.selectFragment = selectFragment
        self.removeFragment = removeFragment
        self.draftText = draftText
        self.selectedTokenIDs = selectedTokenIDs
        self.editText = editText
        self.selectToken = selectToken
        self.removeToken = removeToken
        self.resetSelection = resetSelection
        self.selectedLayers = selectedLayers
        self.selectLayer = selectLayer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(activityKindLabel)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("activity-kind-\(activity.kind.rawValue)")

            switch activity {
            case let .codeOrdering(ordering):
                CodeOrderingActivityView(
                    activity: ordering,
                    selectedFragmentIDs: selectedFragmentIDs,
                    codeIdentifier: codeIdentifier,
                    selectFragment: selectFragment,
                    removeFragment: removeFragment,
                    resetSelection: resetSelection,
                    reduceMotion: reduceMotion
                )
            case .missingCode, .outputPrediction, .diagnosticSelection, .codeRepair:
                CodeChoiceActivityView(
                    prompt: activity.prompt,
                    code: activity.code(selectedChoiceID: selectedChoiceID),
                    choices: activity.choices,
                    selectedChoiceID: selectedChoiceID,
                    codeIdentifier: codeIdentifier,
                    choiceIdentifierPrefix: choiceIdentifierPrefix,
                    selectChoice: selectChoice,
                    reduceMotion: reduceMotion
                )
            case let .constrainedEditing(editing):
#if os(tvOS)
                ConstrainedTokenEditingView(
                    activity: editing,
                    draftText: draftText,
                    selectedTokenIDs: selectedTokenIDs,
                    codeIdentifier: codeIdentifier,
                    selectToken: selectToken,
                    removeToken: removeToken,
                    resetSelection: resetSelection,
                    reduceMotion: reduceMotion
                )
#else
                ConstrainedTextEditingView(
                    activity: editing,
                    draftText: draftText,
                    codeIdentifier: codeIdentifier,
                    editText: editText,
                    resetSelection: resetSelection,
                    reduceMotion: reduceMotion
                )
#endif
            case let .unitTestAuthoring(test):
                AuthoredTestActivityView(
                    composition: test.composition,
                    framework: test.framework,
                    targetLabel: "Target: \(test.target)",
                    assertionLabel: "Required assertion: \(test.requiredAssertion)",
                    expectedLabel: "Expected: \(test.expectedOutcome)",
                    draftText: draftText,
                    selectedTokenIDs: selectedTokenIDs,
                    codeIdentifier: codeIdentifier,
                    editText: editText,
                    selectToken: selectToken,
                    removeToken: removeToken,
                    resetSelection: resetSelection,
                    reduceMotion: reduceMotion
                )
            case let .uiTestAuthoring(test):
                AuthoredTestActivityView(
                    composition: test.composition,
                    framework: test.framework,
                    targetLabel: "Entry ID: \(test.entryIdentifier)",
                    assertionLabel: nil,
                    expectedLabel: "Result ID: \(test.resultIdentifier)",
                    draftText: draftText,
                    selectedTokenIDs: selectedTokenIDs,
                    codeIdentifier: codeIdentifier,
                    editText: editText,
                    selectToken: selectToken,
                    removeToken: removeToken,
                    resetSelection: resetSelection,
                    reduceMotion: reduceMotion
                )
            case let .architectureClassification(classification):
                ArchitectureClassificationView(
                    activity: classification,
                    selectedLayers: selectedLayers,
                    selectLayer: selectLayer
                )
            case let .projectValidation(validation):
                ProjectValidationActivityView(activity: validation)
            }
        }
    }

    private var activityKindLabel: String {
        switch activity.kind {
        case .missingCode:
            "Missing Code"
        case .outputPrediction:
            "Output Prediction"
        case .codeOrdering:
            "Code Ordering"
        case .diagnosticSelection:
            "Diagnostic Selection"
        case .codeRepair:
            "Code Repair"
        case .constrainedEditing:
            "Constrained Editing"
        case .unitTestAuthoring:
            "Unit-Test Authoring"
        case .uiTestAuthoring:
            "UI-Test Authoring"
        case .architectureClassification:
            "Architecture Classification"
        case .projectValidation:
            "Project Validation"
        }
    }
}

private struct ProjectValidationActivityView: View {
    let activity: ProjectValidationActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(activity.prompt)
                .font(.headline)
                .accessibilityIdentifier("activity-prompt")
            ForEach(activity.checklist) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Label(item.title, systemImage: symbol(for: item.status))
                        .accessibilityIdentifier("project-validation-item-\(item.id)")
                        .accessibilityValue(value(for: item.status))
                    if let feedback = item.feedback {
                        Text(feedback)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if let submission = activity.submission {
                Text(submission.isPassed ? "Project validation passed" : "Project needs review")
                    .font(.headline)
                    .accessibilityIdentifier("project-validation-result")
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func symbol(for status: ProjectValidationStatus) -> String {
        switch status {
        case .pending: "circle"
        case .passed: "checkmark.circle.fill"
        case .needsReview: "arrow.counterclockwise.circle.fill"
        }
    }

    private func value(for status: ProjectValidationStatus) -> String {
        switch status {
        case .pending: "Pending"
        case .passed: "Passed"
        case .needsReview: "Needs review"
        }
    }
}

private struct CodeOrderingActivityView: View {
    let activity: CodeOrderingActivity
    let selectedFragmentIDs: [String]
    let codeIdentifier: String
    let selectFragment: (String) -> Void
    let removeFragment: (String) -> Void
    let resetSelection: () -> Void
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ActivityCodePreview(
                code: selectedFragmentIDs.isEmpty
                    ? "Choose lines to build the code."
                    : activity.code(selectedFragmentIDs: selectedFragmentIDs),
                identifier: codeIdentifier,
                reduceMotion: reduceMotion
            )

            Text(activity.prompt)
                .font(.headline)
                .accessibilityIdentifier("activity-prompt")

            SequenceComposerControls(
                tokens: activity.fragments,
                selectedIDs: selectedFragmentIDs,
                availableTitle: "Available lines",
                removeInstruction: "Your order — choose a line to remove it",
                availableIdentifierPrefix: "activity-fragment-",
                selectedIdentifierPrefix: "activity-ordered-",
                selectToken: selectFragment,
                removeToken: removeFragment,
                resetSelection: resetSelection
            )
        }
    }
}

private struct ActivityCodePreview: View {
    let code: String
    let identifier: String
    let reduceMotion: Bool

    var body: some View {
        Text(code)
            .font(.system(.title3, design: .monospaced, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                Color.primary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .contentTransition(.opacity)
            .animation(LearningMotion.selection(reduceMotion: reduceMotion), value: code)
            .accessibilityIdentifier(identifier)
    }
}

private struct AuthoredTestActivityView: View {
    let composition: ConstrainedEditingActivity
    let framework: String
    let targetLabel: String
    let assertionLabel: String?
    let expectedLabel: String
    let draftText: String
    let selectedTokenIDs: [String]
    let codeIdentifier: String
    let editText: (String) -> Void
    let selectToken: (String) -> Void
    let removeToken: (String) -> Void
    let resetSelection: () -> Void
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(framework)
                .font(.subheadline.bold())
            Text(targetLabel)
                .font(.subheadline.monospaced())
            if let assertionLabel {
                Text(assertionLabel)
                    .font(.subheadline.monospaced())
                    .accessibilityIdentifier("activity-required-assertion")
            }
            Text(expectedLabel)
                .font(.subheadline.monospaced())
#if os(tvOS)
            ConstrainedTokenEditingView(
                activity: composition,
                draftText: draftText,
                selectedTokenIDs: selectedTokenIDs,
                codeIdentifier: codeIdentifier,
                selectToken: selectToken,
                removeToken: removeToken,
                resetSelection: resetSelection,
                reduceMotion: reduceMotion
            )
#else
            ConstrainedTextEditingView(
                activity: composition,
                draftText: draftText,
                codeIdentifier: codeIdentifier,
                editText: editText,
                resetSelection: resetSelection,
                reduceMotion: reduceMotion
            )
#endif
        }
    }
}

private struct ArchitectureClassificationView: View {
    let activity: ArchitectureClassificationActivity
    let selectedLayers: [String: ArchitectureLayer]
    let selectLayer: (String, ArchitectureLayer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(activity.prompt)
                .font(.headline)
                .accessibilityIdentifier("activity-prompt")
            ForEach(activity.items) { item in
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.responsibility)
                        .font(.body.bold())
                        .accessibilityIdentifier("activity-boundary-\(item.id)")
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            layerButtons(for: item)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            layerButtons(for: item)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func layerButtons(for item: ArchitectureBoundaryItem) -> some View {
        ForEach(ArchitectureLayer.allCases, id: \.self) { layer in
            Button {
                selectLayer(item.id, layer)
            } label: {
                Text(layer.rawValue.capitalized)
                    .frame(minWidth: 90)
            }
            .buttonStyle(.bordered)
            .tint(selectedLayers[item.id] == layer ? .accentColor : .secondary)
            .accessibilityIdentifier("activity-layer-\(item.id)-\(layer.rawValue)")
            .accessibilityValue(
                selectedLayers[item.id] == layer ? "Selected" : "Not selected"
            )
        }
    }
}

#if !os(tvOS)
private struct ConstrainedTextEditingView: View {
    let activity: ConstrainedEditingActivity
    let draftText: String
    let codeIdentifier: String
    let editText: (String) -> Void
    let resetSelection: () -> Void
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ActivityCodePreview(
                code: activity.code(
                    enteredText: draftText.isEmpty ? activity.starterText : draftText
                ),
                identifier: codeIdentifier,
                reduceMotion: reduceMotion
            )
            Text(activity.prompt)
                .font(.headline)
                .accessibilityIdentifier("activity-prompt")
            TextField(
                "Replace \(activity.starterText)",
                text: Binding(get: { draftText }, set: { newText in
                    editText(newText)
                })
            )
            .font(.body.monospaced())
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Editable Swift expression")
            .accessibilityIdentifier("activity-editor")
            Text("\(draftText.count) of \(activity.maxLength) characters")
                .font(.caption)
                .foregroundStyle(
                    draftText.count > activity.maxLength ? Color.red : Color.secondary
                )
                .accessibilityIdentifier("activity-editor-limit")
            if draftText.isEmpty == false {
                Button("Reset composition") {
                    resetSelection()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("activity-reset-composition")
            }
        }
    }
}
#else
private struct ConstrainedTokenEditingView: View {
    let activity: ConstrainedEditingActivity
    let draftText: String
    let selectedTokenIDs: [String]
    let codeIdentifier: String
    let selectToken: (String) -> Void
    let removeToken: (String) -> Void
    let resetSelection: () -> Void
    let reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ActivityCodePreview(
                code: activity.code(
                    enteredText: draftText.isEmpty ? activity.starterText : draftText
                ),
                identifier: codeIdentifier,
                reduceMotion: reduceMotion
            )
            Text(activity.prompt)
                .font(.headline)
                .accessibilityIdentifier("activity-prompt")
            SequenceComposerControls(
                tokens: activity.tokens,
                selectedIDs: selectedTokenIDs,
                availableTitle: "Available expression tokens",
                removeInstruction: "Your expression — choose a token to remove it",
                availableIdentifierPrefix: "activity-token-",
                selectedIdentifierPrefix: "activity-composed-",
                selectToken: selectToken,
                removeToken: removeToken,
                resetSelection: resetSelection
            )
        }
    }
}
#endif

private struct SequenceComposerControls: View {
    let tokens: [LearningChoice]
    let selectedIDs: [String]
    let availableTitle: String
    let removeInstruction: String
    let availableIdentifierPrefix: String
    let selectedIdentifierPrefix: String
    let selectToken: (String) -> Void
    let removeToken: (String) -> Void
    let resetSelection: () -> Void

#if os(tvOS)
    @FocusState private var focusedTokenID: String?
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(availableTitle)
                .font(.subheadline.bold())
            ForEach(tokens) { token in
                Button {
                    selectToken(token.id)
                } label: {
                    Text(token.code)
                        .font(.body.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(selectedIDs.contains(token.id) ? .accentColor : .secondary)
                .accessibilityIdentifier("\(availableIdentifierPrefix)\(token.id)")
                .accessibilityValue(
                    selectedIDs.contains(token.id) ? "Added" : "Available"
                )
#if os(tvOS)
                .focused($focusedTokenID, equals: token.id)
#endif
            }
            if selectedIDs.isEmpty == false {
                Text(removeInstruction)
                    .font(.subheadline.bold())
                Button("Reset composition") {
                    resetSelection()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("activity-reset-composition")
            }
            ForEach(selectedIDs, id: \.self) { id in
                if let token = tokens.first(where: { $0.id == id }),
                   let index = selectedIDs.firstIndex(of: id) {
                    Button {
                        removeToken(id)
                    } label: {
                        Text("\(index + 1). \(token.code)")
                            .font(.body.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("\(selectedIdentifierPrefix)\(id)")
                }
            }
        }
#if os(tvOS)
        .defaultFocus($focusedTokenID, tokens.first?.id)
#endif
    }
}

struct CodeChoiceActivityView: View {
    let prompt: String
    let code: String
    let choices: [LearningChoice]
    let selectedChoiceID: String?
    let codeIdentifier: String
    let choiceIdentifierPrefix: String
    let selectChoice: (String) -> Void
    let reduceMotion: Bool

#if os(tvOS)
    @FocusState private var focusedChoiceID: String?
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(code)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    Color.primary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .contentTransition(.opacity)
                .animation(
                    LearningMotion.selection(reduceMotion: reduceMotion),
                    value: selectedChoiceID
                )
                .accessibilityIdentifier(codeIdentifier)

            Text(prompt)
                .font(.headline)
                .accessibilityIdentifier("activity-prompt")

            HStack(spacing: 12) {
                ForEach(choices) { choice in
                    Button {
                        selectChoice(choice.id)
                    } label: {
                        HStack {
                            Text(choice.code)
                                .font(.body.monospaced().weight(.semibold))
                            if selectedChoiceID == choice.id {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(minWidth: 90)
                    }
                    .buttonStyle(.bordered)
                    .tint(
                        selectedChoiceID == choice.id
                            ? Color.accentColor
                            : Color.secondary
                    )
                    .accessibilityIdentifier("\(choiceIdentifierPrefix)\(choice.id)")
                    .accessibilityValue(
                        selectedChoiceID == choice.id ? "Selected" : "Not selected"
                    )
                    .scaleEffect(
                        selectedChoiceID == choice.id && !reduceMotion ? 1.04 : 1
                    )
                    .animation(
                        LearningMotion.selection(reduceMotion: reduceMotion),
                        value: selectedChoiceID
                    )
#if os(tvOS)
                    .focused($focusedChoiceID, equals: choice.id)
#endif
                }
            }
        }
#if os(tvOS)
        .defaultFocus($focusedChoiceID, choices.first?.id)
        .task(id: choiceIdentifierPrefix) {
            // A new step can reuse the same first choice ID. Clear focus before requesting it.
            focusedChoiceID = nil
            await Task.yield()
            focusedChoiceID = choices.first?.id
        }
#endif
    }
}
