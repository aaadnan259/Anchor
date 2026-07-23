import SwiftUI
import Charts

struct TimeOfDayChartView: View {
    let slices: [TimeOfDaySlice]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let headline {
                Text(headline)
                    .font(.anchorFootnote)
                    .foregroundStyle(.secondary)
            }

            Chart(slices) { slice in
                BarMark(
                    x: .value("Period", slice.period.displayName),
                    y: .value("Completions", slice.count)
                )
                .foregroundStyle(tint)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)")
                        }
                    }
                }
            }
            .font(.anchorFootnote)
            .frame(height: 140)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Completions by time of day")
            .accessibilityValue(summary)
        }
    }

    private var totalCount: Int { slices.reduce(0) { $0 + $1.count } }

    private var headline: String? {
        guard totalCount > 0, let top = slices.max(by: { $0.count < $1.count }), top.count > 0 else {
            return nil
        }
        return "Usually completed in the \(top.period.displayName)"
    }

    private var summary: String {
        guard totalCount > 0 else { return "No completions yet" }
        return slices.map { "\($0.period.displayName): \($0.count)" }.joined(separator: ", ")
    }
}

#Preview {
    TimeOfDayChartView(
        slices: [
            TimeOfDaySlice(period: .night, count: 1),
            TimeOfDaySlice(period: .morning, count: 8),
            TimeOfDaySlice(period: .afternoon, count: 3),
            TimeOfDaySlice(period: .evening, count: 2)
        ],
        tint: AccentColor.violet.color
    )
    .padding()
}
