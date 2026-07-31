import SwiftUI

struct ProgressRingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = .accentColor
    var size: CGFloat = 64
    var accessibilityLabelText: String = "Progress"
    /// Soft pulsing glow behind the filled arc — reserved for the one prominent ring (Today's overall progress).
    var pulseGlow: Bool = false

    @State private var isPulsing = false

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            if pulseGlow {
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(tint, style: StrokeStyle(lineWidth: lineWidth * 1.6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .opacity(reduceMotion ? 0.25 : (isPulsing ? 0.45 : 0.15))
                    .scaleEffect(reduceMotion ? 1 : (isPulsing ? 1.05 : 1))
            }
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
        .onAppear {
            guard pulseGlow, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.65, tint: AccentColor.indigo.color, size: 100)
}
