import SwiftUI
import WidgetKit

@main
struct SwiftLearnWatchWidgets: WidgetBundle {
    var body: some Widget {
        SwiftLearnProgressWidget()
    }
}

struct SwiftLearnProgressWidget: Widget {
    static let kind = "SwiftLearnProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: SwiftLearnWidgetProvider()
        ) { entry in
            SwiftLearnWidgetView(presentation: entry.presentation)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Swift Learn")
        .description("Learning progress and reviews due.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct SwiftLearnWidgetEntry: TimelineEntry {
    let date: Date
    let presentation: WatchWidgetPresentation
}

/// Reads the shared snapshot written by the Watch app. The widget performs no
/// synchronization, persistence, or answer evaluation of its own.
struct SwiftLearnWidgetProvider: TimelineProvider {
    private static let refreshInterval: TimeInterval = 30 * 60

    func placeholder(in context: Context) -> SwiftLearnWidgetEntry {
        SwiftLearnWidgetEntry(
            date: .now,
            presentation: WatchWidgetPresentation(snapshot: nil)
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SwiftLearnWidgetEntry) -> Void
    ) {
        completion(currentEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SwiftLearnWidgetEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [currentEntry()],
                policy: .after(.now.addingTimeInterval(Self.refreshInterval))
            )
        )
    }

    private func currentEntry() -> SwiftLearnWidgetEntry {
        SwiftLearnWidgetEntry(
            date: .now,
            presentation: WatchWidgetPresentation(
                snapshot: WatchSharedStore.loadSnapshot()
            )
        )
    }
}

struct SwiftLearnWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let presentation: WatchWidgetPresentation

    var body: some View {
        content
            .widgetURL(WatchWidgetPresentation.deepLinkURL)
            .accessibilityLabel(presentation.accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Text(presentation.inlineText)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Swift Learn")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(presentation.headline)
                    .font(.headline)
                    .lineLimit(1)
                Text(presentation.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Gauge(value: presentation.progress) {
                Image(systemName: "swift")
            } currentValueLabel: {
                Text(presentation.progressText)
                    .font(.caption2.monospacedDigit())
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.orange)
        }
    }
}
