import SwiftUI

/// Drop-in replacement for `Image(systemName:)` that also renders emoji habit icons.
/// Callers keep applying their own `.font()`/`.foregroundStyle()` exactly as before.
struct HabitIconView: View {
    let icon: String

    var body: some View {
        if icon.isSFSymbolCompatible {
            Image(systemName: icon)
        } else {
            Text(icon)
        }
    }
}

#Preview {
    HStack(spacing: Spacing.md) {
        HabitIconView(icon: "drop.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(AccentColor.sky.color)
        HabitIconView(icon: "💧")
            .font(.system(size: 20))
    }
    .padding()
}
