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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(activityKindLabel)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("activity-kind-\(activity.kind.rawValue)")

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
        }
    }

    private var activityKindLabel: String {
        switch activity.kind {
        case .missingCode:
            "Missing Code"
        case .outputPrediction:
            "Output Prediction"
        }
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
