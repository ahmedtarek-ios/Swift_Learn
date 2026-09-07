//
//  BossChallengeView.swift
//  Swift Learn
//
//  Created by Codex on 01/09/2026.
//

import SwiftUI

struct BossChallengeView: View {
    @State private var viewModel: BossChallengeViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    init(viewModel: BossChallengeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("LEVEL BOSS")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if let challenge = viewModel.availability?.challenge {
                    Text(challenge.title)
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("boss-challenge-title")
                    Text(challenge.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                if let result = viewModel.result {
                    resultView(result)
                } else if let item = viewModel.currentItem {
                    challengeItem(item)
                } else if case let .failed(message) = viewModel.loadState {
                    ContentUnavailableView {
                        Label("Boss Unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    }
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
        .navigationTitle("Boss Challenge")
        .onAppear(perform: viewModel.startSession)
    }

    private func challengeItem(_ item: BossChallengeItem) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.stepSummary)
                .font(.headline)
                .accessibilityIdentifier("boss-challenge-step")
            Text(item.lesson.title)
                .font(.title2.bold())
                .accessibilityIdentifier("boss-item-\(item.id)")

            LearningActivityRenderer(
                activity: item.lesson.activity,
                selectedChoiceID: viewModel.selectedChoiceID,
                codeIdentifier: "boss-code-\(item.id)",
                choiceIdentifierPrefix: "boss-choice-\(item.id)-",
                selectChoice: viewModel.selectChoice,
                reduceMotion: reduceMotion
            )

            Button("Check Challenge", action: viewModel.submitCurrentAnswer)
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedChoiceID == nil)
                .accessibilityIdentifier("submit-boss-answer")

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("boss-challenge-error")
            }
        }
    }

    private func resultView(_ result: BossChallengeResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                result.isPassed ? "Boss defeated" : "Boss challenge complete",
                systemImage: result.isPassed ? "crown.fill" : "arrow.clockwise.circle"
            )
            .font(.title.bold())
            .foregroundStyle(result.isPassed ? Color.green : Color.orange)
            .accessibilityIdentifier(
                result.isPassed ? "boss-challenge-passed" : "boss-challenge-failed"
            )

            Text("\(result.correctAnswerCount) of \(result.answers.count) skills verified")
                .font(.headline)
                .accessibilityIdentifier("boss-challenge-result-summary")

            Text(
                result.isPassed
                    ? "Your challenge evidence now contributes to mastery."
                    : "Missed skills are now available to the review system."
            )
            .foregroundStyle(.secondary)

            if let completionSaveError = viewModel.completionSaveError {
                Text(completionSaveError)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("boss-completion-save-error")
                Button("Try Saving Achievement Again") {
                    viewModel.retryCompletionSave()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("retry-boss-completion-save")
            }
        }
        .padding()
        .background(
            (result.isPassed ? Color.green : Color.orange).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }
}
