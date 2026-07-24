import SwiftUI

struct ProgressRingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = .accentColor
    var size: CGFloat = 64
    var accessibilityLabelText: String = "Progress"

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.75), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .linear(duration: 0.1) : Motion.snappy, value: clamped)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    ProgressRingView(progress: 0.65, tint: AccentColor.indigo.color, size: 100)
}
