import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(SettingsService.self) private var settingsService

    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        Group {
            if let viewModel {
                stepContent(viewModel: viewModel)
            } else {
                Color.clear
            }
        }
        .background(Surface.background)
        .task {
            if viewModel == nil {
                viewModel = OnboardingViewModel(
                    habitService: HabitService(context: modelContext),
                    notificationService: NotificationService(),
                    locationService: locationService,
                    settingsService: settingsService
                )
            }
        }
    }

    @ViewBuilder
    private func stepContent(viewModel: OnboardingViewModel) -> some View {
        switch viewModel.currentStep {
        case .welcome:
            welcomeStep(viewModel: viewModel)
        case .habits:
            habitsStep(viewModel: viewModel)
        case .notifications:
            notificationsStep(viewModel: viewModel)
        case .location:
            locationStep(viewModel: viewModel)
        }
    }

    private func welcomeStep(viewModel: OnboardingViewModel) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(settingsService.effectiveAccentColor)

            VStack(spacing: Spacing.sm) {
                Text("Anchor")
                    .font(.anchorLargeTitle)
                Text("Track any habit, your way.")
                    .font(.anchorBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()

            PrimaryButtonView(title: "Get Started", tint: settingsService.effectiveAccentColor) {
                viewModel.advance()
            }
        }
        .padding(Spacing.lg)
    }

    private func habitsStep(viewModel: OnboardingViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Choose Your Habits")
                            .font(.anchorLargeTitle)
                        Text("Start with a few suggestions, or skip and add your own later.")
                            .font(.anchorBody)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                    VStack(spacing: Spacing.sm) {
                        ForEach(HabitPreset.all) { preset in
                            presetRow(preset, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, Spacing.lg)
            }

            PrimaryButtonView(title: "Continue", tint: settingsService.effectiveAccentColor) {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    private func presetRow(_ preset: HabitPreset, viewModel: OnboardingViewModel) -> some View {
        let isSelected = viewModel.isSelected(preset)
        return Button {
            Haptics.light()
            viewModel.toggle(preset)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(preset.accentColor.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .stroke(preset.accentColor.color.opacity(0.35), lineWidth: 1)
                        )
                    HabitIconView(icon: preset.icon)
                        .foregroundStyle(preset.accentColor.color)
                }
                .frame(width: 44, height: 44)

                Text(preset.title)
                    .font(.anchorHeadline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? preset.accentColor.color : Color.secondary.opacity(0.4))
            }
            .padding(Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(isSelected ? preset.accentColor.color.opacity(0.5) : Surface.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func notificationsStep(viewModel: OnboardingViewModel) -> some View {
        primingStep(
            icon: "bell.badge.fill",
            tint: AccentColor.amber.color,
            title: "Stay on Track",
            message: "Get a reminder when it's time for a habit, right when you need it.",
            primaryTitle: "Enable Notifications",
            primaryAction: { viewModel.requestNotifications() },
            skipAction: { viewModel.advance() }
        )
    }

    private func locationStep(viewModel: OnboardingViewModel) -> some View {
        primingStep(
            icon: "location.fill",
            tint: AccentColor.sky.color,
            title: "Accurate Prayer Times",
            message: "Anchor uses your location only to calculate accurate prayer times. It's never stored or shared.",
            primaryTitle: "Enable Location",
            primaryAction: { viewModel.requestLocation() },
            skipAction: { viewModel.advance() }
        )
    }

    private func primingStep(
        icon: String,
        tint: Color,
        title: String,
        message: String,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        skipAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .overlay(Circle().stroke(tint.opacity(0.35), lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 72, height: 72)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.anchorTitle)
                Text(message)
                    .font(.anchorBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()

            VStack(spacing: Spacing.sm) {
                PrimaryButtonView(title: primaryTitle, tint: tint, action: primaryAction)
                Button("Not Now", action: skipAction)
                    .font(.anchorBody)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }
        }
        .padding(Spacing.lg)
    }
}
