import SwiftUI

struct HabitCardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let icon: String
    let title: String
    let subtitle: String?
    let tint: Color
    let streak: Int
    let isCompleted: Bool
    let progress: Double?
    var isExpandable: Bool = false
    var isExpanded: Bool = false
    var isQuantifiable: Bool = false
    var isShielded: Bool = false
    var supportsShields: Bool = false
    let onToggleCompletion: () -> Void
    var onTapExpand: (() -> Void)? = nil
    var onTapLogValue: (() -> Void)? = nil
    var onToggleShield: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .stroke(tint.opacity(0.35), lineWidth: 1)
                    )
                HabitIconView(icon: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.anchorHeadline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.anchorFootnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                    Text("\(streak)")
                        .font(.anchorNumeric)
                }
                .foregroundStyle(.orange)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(streak) day streak")
            }

            if isShielded {
                Image(systemName: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .accessibilityLabel("Shielded today")
            }

            if isExpandable {
                Button {
                    withAnimation(reduceMotion ? .linear(duration: 0.1) : Motion.snappy) {
                        onTapExpand?()
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        ProgressRingView(progress: progress ?? 0, lineWidth: 4, tint: tint, size: 28)
                            .overlay {
                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(tint)
                                }
                            }
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
            } else if isQuantifiable {
                Button {
                    onTapLogValue?()
                } label: {
                    ProgressRingView(progress: progress ?? 0, lineWidth: 4, tint: tint, size: 28)
                        .overlay {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(tint)
                            }
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log amount")
            } else {
                CompletionToggleView(isCompleted: isCompleted, tint: tint, action: onToggleCompletion)
            }
        }
        .padding(Spacing.base)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .fill(Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Surface.border, lineWidth: 1)
        )
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: CornerRadius.card,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CornerRadius.card,
                style: .continuous
            )
            .fill(tint)
            .frame(height: 3)
        }
        .accessibilityElement(children: .combine)
        .contextMenu {
            if supportsShields {
                Button {
                    onToggleShield?()
                } label: {
                    Label(
                        isShielded ? "Remove Shield" : "Shield Today",
                        systemImage: isShielded ? "shield.slash" : "shield.fill"
                    )
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        HabitCardView(
            icon: "dumbbell.fill",
            title: "Gym",
            subtitle: "3 of 5 this week",
            tint: AccentColor.coral.color,
            streak: 4,
            isCompleted: false,
            progress: nil,
            onToggleCompletion: {}
        )
        HabitCardView(
            icon: "moon.stars.fill",
            title: "Prayer",
            subtitle: "3 of 5 today",
            tint: AccentColor.violet.color,
            streak: 12,
            isCompleted: false,
            progress: 0.6,
            isExpandable: true,
            isExpanded: false,
            onToggleCompletion: {},
            onTapExpand: {}
        )
    }
    .padding()
    .background(Surface.background)
}
