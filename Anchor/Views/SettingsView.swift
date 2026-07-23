import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsService.self) private var settingsService

    @State private var notificationStatus: NotificationAuthorization = .notDetermined
    @State private var csvExportURL: URL?
    @State private var jsonExportURL: URL?
    @State private var biometryKind: BiometryKind = .none

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    prayerTimesSection
                    appearanceSection
                    notificationsSection
                    securitySection
                    dataSection
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
                biometryKind = AuthenticationService().biometryKind()
                let habits = HabitService(context: modelContext).fetchAll()
                let exportService = ExportService()
                csvExportURL = exportService.csvFileURL(habits: habits)
                jsonExportURL = exportService.jsonFileURL(habits: habits)
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
        VStack(alignment: .leading, spacing: Spacing.base) {
            SectionHeaderView(title: "Appearance")

            Picker("Theme", selection: Bindable(settingsService).appearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.base)

            AccentColorPickerView(selection: Bindable(settingsService).accentColor)
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

                Divider().padding(.horizontal, Spacing.base)

                Toggle("Smart Reminders", isOn: Bindable(settingsService).smartRemindersEnabled)
                    .font(.anchorBody)
                    .padding(Spacing.base)
                    .onChange(of: settingsService.smartRemindersEnabled) { _, isEnabled in
                        guard isEnabled else { return }
                        Task {
                            let service = NotificationService()
                            await service.requestAuthorizationIfNeeded()
                            notificationStatus = await service.authorizationStatus()
                        }
                    }

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

            Text("Get a reminder around 8:00 PM for any habit you haven't completed yet today.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.base)
        }
    }

    @ViewBuilder
    private var securitySection: some View {
        if biometryKind != .none {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "Security")
                Toggle(biometricToggleLabel, isOn: Bindable(settingsService).biometricLockEnabled)
                    .font(.anchorBody)
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
    }

    private var biometricToggleLabel: String {
        switch biometryKind {
        case .faceID: "Require Face ID"
        case .touchID: "Require Touch ID"
        case .none: ""
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Data")
            VStack(spacing: 0) {
                if let csvExportURL {
                    ShareLink(item: csvExportURL) {
                        exportRow(title: "Export as CSV")
                    }
                }

                if csvExportURL != nil && jsonExportURL != nil {
                    Divider().padding(.horizontal, Spacing.base)
                }

                if let jsonExportURL {
                    ShareLink(item: jsonExportURL) {
                        exportRow(title: "Export as JSON")
                    }
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

            Text("Exports your full habit and completion history.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.base)
        }
    }

    private func exportRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.anchorBody)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.base)
        .contentShape(Rectangle())
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
