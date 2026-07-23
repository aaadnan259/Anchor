import SwiftUI

struct WeeklyBarsView: View {
    let rates: [Double]
    let tint: Color
    var barWidth: CGFloat = 14
    var maxHeight: CGFloat = 36

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(Array(rates.enumerated()), id: \.offset) { _, rate in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: barWidth, height: maxHeight)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(tint)
                            .frame(height: max(4, maxHeight * CGFloat(min(max(rate, 0), 1))))
                    }
            }
        }
        .frame(height: maxHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly completion")
        .accessibilityValue(rates.map { "\(Int($0 * 100)) percent" }.joined(separator: ", "))
    }
}

#Preview {
    WeeklyBarsView(rates: [0.4, 0.8, 1.0, 0.6], tint: AccentColor.indigo.color)
        .padding()
}
