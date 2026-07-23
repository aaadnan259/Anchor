import SwiftUI
import Charts

struct TrendChartView: View {
    let points: [TrendPoint]
    let range: InsightsRange
    let tint: Color

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Date", point.date, unit: bucketComponent),
                y: .value("Completion", point.rate)
            )
            .foregroundStyle(tint)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("Date", point.date, unit: bucketComponent),
                y: .value("Completion", point.rate)
            )
            .foregroundStyle(tint)
            .symbolSize(24)
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.5, 1.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let rate = value.as(Double.self) {
                        Text("\(Int(rate * 100))%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: bucketComponent, count: strideCount)) { value in
                AxisGridLine()
                AxisValueLabel(format: axisFormat)
            }
        }
        .font(.anchorFootnote)
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(range.displayName) completion trend")
        .accessibilityValue(summary)
    }

    private var bucketComponent: Calendar.Component {
        switch range {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    private var strideCount: Int {
        switch range {
        case .week: 2
        case .month: 2
        case .year: 1
        }
    }

    private var axisFormat: Date.FormatStyle {
        switch range {
        case .week: .dateTime.month(.abbreviated).day()
        case .month: .dateTime.month(.abbreviated)
        case .year: .dateTime.year()
        }
    }

    private var summary: String {
        guard !points.isEmpty else { return "No data yet" }
        return points.map { "\(Int($0.rate * 100)) percent" }.joined(separator: ", ")
    }
}

#Preview {
    TrendChartView(
        points: (0..<12).map { i in
            TrendPoint(date: Calendar.current.date(byAdding: .weekOfYear, value: -i, to: .now) ?? .now, rate: Double.random(in: 0...1))
        }.reversed(),
        range: .week,
        tint: AccentColor.indigo.color
    )
    .padding()
}
