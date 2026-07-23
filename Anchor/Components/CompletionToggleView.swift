import SwiftUI

struct CompletionToggleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isCompleted: Bool
    var tint: Color = .accentColor
    var size: CGFloat = 32
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            withAnimation(reduceMotion ? .linear(duration: 0.1) : Motion.bouncy) {
                action()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isCompleted ? tint : Color.clear)
                    .overlay(
                        Circle().strokeBorder(isCompleted ? Color.clear : tint.opacity(0.4), lineWidth: 2)
                    )
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Circle())
        .accessibilityLabel(isCompleted ? "Completed" : "Mark as complete")
        .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
    }
}

#Preview {
    HStack(spacing: 20) {
        CompletionToggleView(isCompleted: false, tint: AccentColor.teal.color) {}
        CompletionToggleView(isCompleted: true, tint: AccentColor.teal.color) {}
    }
    .padding()
}
