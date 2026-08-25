//
//  CodeChoiceActivityView.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import SwiftUI

struct CodeChoiceActivityView: View {
    let lesson: LearningLesson
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
            Text(lesson.code(selectedChoiceID: selectedChoiceID))
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

            Text("Choose the missing Swift code")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(lesson.choices) { choice in
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
        .onAppear {
            focusedChoiceID = lesson.choices.first?.id
        }
#endif
    }
}
