import SwiftUI
import Charts

/// A radial ("wheel") chart, distinct from `TrendChartView`'s line and `TimeOfDayChartView`'s bars —
/// seven equal-angle wedges, one per weekday, whose length encodes that weekday's completion rate.
struct WeekdayRadialChartView: View {
    let slices: [WeekdaySlice]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let headline {
                Text(headline)
                    .font(.anchorFootnote)
                    .foregroundStyle(.secondary)
            }

            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Weekday", 1),
                    innerRadius: .ratio(0.35),
                    outerRadius: .ratio(max(slice.rate, 0.08)),
                    angularInset: 2
                )
                .foregroundStyle(tint.opacity(slice.dueCount == 0 ? 0.15 : 1))
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .frame(height: 180)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Completion rate by day of week")
            .accessibilityValue(summary)
        }
    }

    private var totalDue: Int { slices.reduce(0) { $0 + $1.dueCount } }

    private var headline: String? {
        guard totalDue > 0, let best = slices.filter({ $0.dueCount > 0 }).max(by: { $0.rate < $1.rate }), best.rate > 0 else {
            return nil
        }
        return "Best on \(best.weekday.shortLabel)s"
    }

    private var summary: String {
        guard totalDue > 0 else { return "No data yet" }
        return slices
            .filter { $0.dueCount > 0 }
            .map { "\($0.weekday.shortLabel): \(Int($0.rate * 100)) percent" }
            .joined(separator: ", ")
    }
}

#Preview {
    WeekdayRadialChartView(
        slices: [
            WeekdaySlice(weekday: .sunday, dueCount: 4, completedCount: 1),
            WeekdaySlice(weekday: .monday, dueCount: 4, completedCount: 4),
            WeekdaySlice(weekday: .tuesday, dueCount: 4, completedCount: 3),
            WeekdaySlice(weekday: .wednesday, dueCount: 4, completedCount: 2),
            WeekdaySlice(weekday: .thursday, dueCount: 4, completedCount: 3),
            WeekdaySlice(weekday: .friday, dueCount: 4, completedCount: 1),
            WeekdaySlice(weekday: .saturday, dueCount: 4, completedCount: 2)
        ],
        tint: AccentColor.coral.color
    )
    .padding()
}
