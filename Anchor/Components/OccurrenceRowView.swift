import SwiftUI

struct OccurrenceRowView: View {
    let title: String
    let timeLabel: String?
    let isCompleted: Bool
    let tint: Color
    let onToggleCompletion: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.anchorSubheadline.weight(.medium))
                    .foregroundStyle(.primary)
                if let timeLabel {
                    Text(timeLabel)
                        .font(.anchorFootnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CompletionToggleView(isCompleted: isCompleted, tint: tint, size: 26, action: onToggleCompletion)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.base)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        OccurrenceRowView(title: "Fajr", timeLabel: "5:12 AM", isCompleted: true, tint: AccentColor.violet.color) {}
        OccurrenceRowView(title: "Dhuhr", timeLabel: "1:04 PM", isCompleted: false, tint: AccentColor.violet.color) {}
    }
}
