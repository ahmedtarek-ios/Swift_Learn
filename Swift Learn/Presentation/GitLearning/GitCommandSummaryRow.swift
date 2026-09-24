import SwiftUI

struct GitCommandSummaryRow: View {
    let lesson: GitCommandLesson
    let availability: GitLessonAvailability
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(availability == .completed ? Color.green : Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                Text(lesson.objective)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .background(
            isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }

    private var symbolName: String {
        switch availability {
        case .completed:
            "checkmark.circle.fill"
        case .available:
            "terminal.fill"
        case .locked:
            "lock.fill"
        case .unavailable:
            "exclamationmark.triangle"
        }
    }
}
