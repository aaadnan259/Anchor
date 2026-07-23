import SwiftUI

struct PrimaryButtonView: View {
    let title: String
    var tint: Color = .accentColor
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            Text(title)
                .font(.anchorHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(isDisabled ? tint.opacity(0.35) : tint)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButtonView(title: "Add Habit", tint: AccentColor.indigo.color, action: {})
        PrimaryButtonView(title: "Disabled", tint: AccentColor.indigo.color, isDisabled: true, action: {})
    }
    .padding()
}
