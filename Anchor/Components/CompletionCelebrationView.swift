import SwiftUI

/// A brief, self-contained celebration burst shown once the daily progress ring reaches 100%.
struct CompletionCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let tint: Color

    @State private var isExpanded = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint, lineWidth: 3)
                .scaleEffect(isExpanded ? 1.9 : 0.8)
                .opacity(isExpanded ? 0 : 0.6)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tint)
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            Haptics.success()
            guard !reduceMotion else {
                isVisible = true
                isExpanded = true
                return
            }
            withAnimation(Motion.bouncy) { isVisible = true }
            withAnimation(.easeOut(duration: 0.7)) { isExpanded = true }
        }
    }
}

#Preview {
    CompletionCelebrationView(tint: AccentColor.teal.color)
        .frame(width: 56, height: 56)
}
