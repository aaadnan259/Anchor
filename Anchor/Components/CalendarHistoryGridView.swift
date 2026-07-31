import SwiftUI

/// A month-grid calendar (weekday columns, day numbers) of a habit's completion history —
/// distinct from `HabitHistoryGridView`'s compact dot-matrix heatmap. Purely presentational:
/// every cell's color comes from `stateProvider`, never computed locally.
struct CalendarHistoryGridView: View {
    let month: Date
    let tint: Color
    let stateProvider: (Date) -> DayCompletionState

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 7)

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.anchorFootnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
    }

    /// `nil` entries are leading blanks before the 1st of the month, so the grid aligns to weekday columns.
    private var daysInGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }

        let weekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        var day = monthInterval.start
        while day < monthInterval.end {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    private func dayCell(_ day: Date) -> some View {
        let state = stateProvider(day)
        return Text("\(calendar.component(.day, from: day))")
            .font(.anchorFootnote.weight(.medium))
            .foregroundStyle(state == .notDue ? .secondary : .primary)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(state.color(tint: tint))
            )
            .accessibilityLabel(accessibilityLabel(for: day, state: state))
    }

    private func accessibilityLabel(for day: Date, state: DayCompletionState) -> String {
        let dateText = day.formatted(date: .abbreviated, time: .omitted)
        let stateText: String
        switch state {
        case .completed: stateText = "completed"
        case .shielded: stateText = "shielded"
        case .partial: stateText = "partially completed"
        case .missed: stateText = "missed"
        case .notDue: stateText = "not due"
        }
        return "\(dateText), \(stateText)"
    }
}

#Preview {
    CalendarHistoryGridView(
        month: .now,
        tint: AccentColor.violet.color
    ) { _ in
        [.completed, .completed, .shielded, .partial, .missed, .notDue].randomElement() ?? .notDue
    }
    .padding()
    .background(Surface.background)
}
