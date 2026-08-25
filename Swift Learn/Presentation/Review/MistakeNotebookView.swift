//
//  MistakeNotebookView.swift
//  Swift Learn
//
//  Created by Codex on 25/08/2026.
//

import SwiftUI

struct MistakeNotebookView: View {
    @State private var viewModel: MistakeNotebookViewModel

    init(viewModel: MistakeNotebookViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("Loading mistakes…")
                    .accessibilityIdentifier("mistake-loading")
            case .loaded:
                notebookContent
            case let .failed(message):
                ContentUnavailableView {
                    Label("Notebook Unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again", action: viewModel.load)
                        .accessibilityIdentifier("retry-mistakes")
                }
            }
        }
        .navigationTitle("Mistake Notebook")
        .task {
            if viewModel.loadState == .idle {
                viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var notebookContent: some View {
        if viewModel.entries.isEmpty {
            ContentUnavailableView(
                "No mistakes recorded",
                systemImage: "book.closed",
                description: Text("Incorrect attempts will appear here for focused practice.")
            )
            .accessibilityIdentifier("mistake-empty")
        } else {
            List(viewModel.entries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
                        .font(.headline)
                    Text("\(entry.attempts.count) incorrect attempt\(entry.attempts.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                    if let category = entry.latestErrorCategory {
                        Text(category.rawValue)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("mistake-skill-\(entry.id.rawValue)")
            }
        }
    }
}
