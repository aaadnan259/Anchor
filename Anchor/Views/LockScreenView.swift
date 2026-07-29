import SwiftUI

struct LockScreenView: View {
    @Environment(SettingsService.self) private var settingsService
    @Binding var isUnlocked: Bool

    @State private var biometryKind: BiometryKind = .none
    @State private var authenticationFailed = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(settingsService.effectiveAccentColor.opacity(0.12))
                    .overlay(Circle().stroke(settingsService.effectiveAccentColor.opacity(0.35), lineWidth: 1))
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(settingsService.effectiveAccentColor)
            }
            .frame(width: 72, height: 72)

            VStack(spacing: Spacing.sm) {
                Text("Anchor is Locked")
                    .font(.anchorTitle)
                Text(authenticationFailed ? "Authentication failed. Try again to continue." : "Unlock to view your habits.")
                    .font(.anchorBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)

            Spacer()
            Spacer()

            PrimaryButtonView(title: "Unlock", tint: settingsService.effectiveAccentColor) {
                Task { await authenticate() }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Surface.background)
        .task {
            biometryKind = AuthenticationService().biometryKind()
            await authenticate()
        }
    }

    private var iconName: String {
        switch biometryKind {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .none: "lock.fill"
        }
    }

    private func authenticate() async {
        let success = await AuthenticationService().authenticate()
        if success {
            isUnlocked = true
        } else {
            authenticationFailed = true
        }
    }
}
