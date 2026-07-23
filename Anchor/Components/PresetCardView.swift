import SwiftUI

struct PresetCardView: View {
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .overlay(Circle().stroke(tint.opacity(0.35), lineWidth: 1))
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(width: 48, height: 48)

                Text(title)
                    .font(.anchorCaption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        PresetCardView(icon: "moon.stars.fill", title: "Prayer", tint: AccentColor.violet.color, action: {})
        PresetCardView(icon: "dumbbell.fill", title: "Gym", tint: AccentColor.coral.color, action: {})
    }
    .padding()
}
