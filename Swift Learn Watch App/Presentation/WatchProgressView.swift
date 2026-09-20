import SwiftUI

struct WatchProgressView: View {
    let viewModel: WatchProgressViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.levelTitle)
                        .font(.headline)
                        .accessibilityIdentifier("watch-progress-level-title")
                    if viewModel.hasLevelDetail {
                        ProgressView(value: viewModel.levelProgress)
                            .tint(.orange)
                            .accessibilityHidden(true)
                    }
                    Text(viewModel.levelSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("watch-progress-level-summary")
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: 8) {
                    ForEach(viewModel.rows) { row in
                        HStack {
                            Text(row.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 6)
                            Text(row.value)
                                .font(.caption.monospacedDigit().weight(.semibold))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("watch-progress-row-\(row.id)")
                        .accessibilityLabel("\(row.title), \(row.value)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .navigationTitle("Progress")
        .accessibilityIdentifier("watch-progress-detail")
    }
}
