import SwiftUI

struct HabitHistoryGridView: View {
    /// Oldest to newest, ideally a multiple of 7.
    let days: [DayCompletionState]
    let tint: Color
    var dotSize: CGFloat = 9
    var spacing: CGFloat = 3

    private var columns: [[DayCompletionState]] {
        stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                VStack(spacing: spacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, state in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(color(for: state))
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Completion history")
        .accessibilityValue(summary)
    }

    private var summary: String {
        let completed = days.filter { $0 == .completed }.count
        let due = days.filter { $0 != .notDue }.count
        return due == 0 ? "No days due yet" : "\(completed) of \(due) days completed"
    }

    private func color(for state: DayCompletionState) -> Color {
        switch state {
        case .completed: tint
        case .missed: tint.opacity(0.18)
        case .notDue: Color.primary.opacity(0.05)
        }
    }
}

#Preview {
    HabitHistoryGridView(
        days: (0..<112).map { _ in [.completed, .completed, .missed, .notDue].randomElement() ?? .notDue },
        tint: AccentColor.violet.color
    )
    .padding()
}
