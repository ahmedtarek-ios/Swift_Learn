//
//  ReviewQueueView.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import SwiftUI

struct ReviewQueueView: View {
    @State private var viewModel: ReviewQueueViewModel
    @State private var mistakeViewModel: MistakeNotebookViewModel
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.learnerMotionPreference) private var motionPreference

    init(
        viewModel: ReviewQueueViewModel,
        mistakeViewModel: MistakeNotebookViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        _mistakeViewModel = State(initialValue: mistakeViewModel)
    }

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("Loading reviews…")
                    .accessibilityIdentifier("review-loading")
            case .loaded:
                reviewContent
            case let .failed(message):
                ContentUnavailableView {
                    Label("Reviews Unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again", action: viewModel.load)
                        .accessibilityIdentifier("retry-reviews")
                }
            }
        }
        .navigationTitle("Review")
        .task {
            if viewModel.loadState == .idle {
                viewModel.load()
            }
        }
    }

    private var reviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RETAIN WHAT YOU LEARN")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(viewModel.summary)
                            .font(.title2.bold())
                    }
                    Spacer()
                    NavigationLink("Mistake Notebook") {
                        MistakeNotebookView(viewModel: mistakeViewModel)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("open-mistake-notebook")
                }

                if viewModel.isSessionComplete {
                    Label("Review session complete", systemImage: "checkmark.seal.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("review-session-complete")
                } else if let item = viewModel.currentItem {
                    reviewCard(item)
                } else {
                    ContentUnavailableView(
                        "You're caught up",
                        systemImage: "checkmark.circle",
                        description: Text("New review work will appear when it is due.")
                    )
                    .accessibilityIdentifier("review-empty")
                }
            }
            .frame(maxWidth: 840, alignment: .leading)
            .padding()
        }
    }

    private func reviewCard(_ item: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(
                item.status == .overdue ? "Overdue review" : "Review due",
                systemImage: item.status == .overdue ? "clock.badge.exclamationmark" : "clock"
            )
            .font(.headline)
            .foregroundStyle(item.status == .overdue ? Color.orange : Color.accentColor)

            Text(item.skill.title)
                .font(.largeTitle.bold())
            Text(item.lesson.instruction)
                .font(.title3)

            LearningActivityRenderer(
                activity: item.lesson.activity,
                selectedChoiceID: viewModel.selectedChoiceID,
                codeIdentifier: "review-code",
                choiceIdentifierPrefix: "review-choice-",
                selectChoice: viewModel.selectChoice,
                reduceMotion: reduceMotion
            )

            Button("Check Review") {
                viewModel.submit(skillID: item.id)
                mistakeViewModel.load()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedChoiceID == nil)
            .accessibilityIdentifier("submit-review-answer")

            if let result = viewModel.attemptResult {
                Label(
                    result.isCorrect ? "Remembered" : "Review again",
                    systemImage: result.isCorrect
                        ? "checkmark.circle.fill"
                        : "arrow.counterclockwise"
                )
                .foregroundStyle(result.isCorrect ? Color.green : Color.orange)
                Text(result.feedback)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review-skill-\(item.id.rawValue)")
    }

    private var reduceMotion: Bool {
        LearningMotionPolicy.shouldReduceMotion(
            systemReduceMotion: systemReduceMotion,
            preference: motionPreference
        )
    }
}
