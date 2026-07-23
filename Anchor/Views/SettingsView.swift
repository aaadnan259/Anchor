import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsService.self) private var settingsService

    @State private var notificationStatus: NotificationAuthorization = .notDetermined

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    prayerTimesSection
                    appearanceSection
                    notificationsSection
                    aboutSection
                }
                .padding(.vertical, Spacing.base)
            }
            .background(Surface.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                notificationStatus = await NotificationService().authorizationStatus()
            }
        }
        .preferredColorScheme(settingsService.appearance.colorScheme)
    }

    private var prayerTimesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Prayer Times")
            VStack(spacing: 0) {
                HStack {
                    Text("Method")
                        .font(.anchorBody)
                    Spacer()
                    Picker("Method", selection: Bindable(settingsService).calculationMethod) {
                        ForEach(PrayerCalculationMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                .padding(Spacing.base)

                Divider().padding(.horizontal, Spacing.base)

                HStack {
                    Text("Asr (Madhab)")
                        .font(.anchorBody)
                    Spacer()
                    Picker("Madhab", selection: Bindable(settingsService).madhab) {
                        ForEach(PrayerMadhab.allCases) { madhab in
                            Text(madhab.displayName).tag(madhab)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                .padding(Spacing.base)
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.base)

            Text("Used to calculate Fajr, Dhuhr, Asr, Maghrib, and Isha times for the Prayer habit. Shafi also applies to the Maliki, Hanbali, and Jafari schools.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.base)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Appearance")
            Picker("Theme", selection: Bindable(settingsService).appearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.base)
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Notifications")
            VStack(spacing: 0) {
                HStack {
                    Text("Status")
                        .font(.anchorBody)
                    Spacer()
                    Text(notificationStatusLabel)
                        .font(.anchorBody)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.base)

                if notificationStatus == .denied {
                    Divider().padding(.horizontal, Spacing.base)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open System Settings")
                            .font(.anchorBody)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(Spacing.base)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.base)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "About")
            HStack {
                Text("Version")
                    .font(.anchorBody)
                Spacer()
                Text(versionString)
                    .font(.anchorBody)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.base)
        }
    }

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized: "On"
        case .denied: "Off"
        case .notDetermined: "Not Set"
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
