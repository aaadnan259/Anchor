import Foundation

@Observable
@MainActor
final class OnboardingViewModel {
    enum Step: Equatable {
        case welcome, habits, notifications, location
    }

    private let habitService: HabitService
    private let notificationService: NotificationService
    private let locationService: LocationService
    private let settingsService: SettingsService

    var currentStep: Step = .welcome
    var selectedPresetIDs: Set<HabitPreset.ID>

    init(
        habitService: HabitService,
        notificationService: NotificationService,
        locationService: LocationService,
        settingsService: SettingsService
    ) {
        self.habitService = habitService
        self.notificationService = notificationService
        self.locationService = locationService
        self.settingsService = settingsService
        self.selectedPresetIDs = Set(HabitPreset.all.map(\.id))
    }

    var selectedPresets: [HabitPreset] {
        HabitPreset.all.filter { selectedPresetIDs.contains($0.id) }
    }

    var needsNotificationsStep: Bool {
        selectedPresets.contains { $0.reminderEnabled }
    }

    var needsLocationStep: Bool {
        selectedPresets.contains { $0.occurrenceMode == .prayer }
    }

    func isSelected(_ preset: HabitPreset) -> Bool {
        selectedPresetIDs.contains(preset.id)
    }

    func toggle(_ preset: HabitPreset) {
        if selectedPresetIDs.contains(preset.id) {
            selectedPresetIDs.remove(preset.id)
        } else {
            selectedPresetIDs.insert(preset.id)
        }
    }

    func advance() {
        if let next = nextStep(after: currentStep) {
            currentStep = next
        } else {
            complete()
        }
    }

    func requestNotifications() {
        Task {
            await notificationService.requestAuthorizationIfNeeded()
            advance()
        }
    }

    func requestLocation() {
        locationService.requestAuthorizationIfNeeded()
        advance()
    }

    private func nextStep(after step: Step) -> Step? {
        switch step {
        case .welcome:
            .habits
        case .habits:
            needsNotificationsStep ? .notifications : (needsLocationStep ? .location : nil)
        case .notifications:
            needsLocationStep ? .location : nil
        case .location:
            nil
        }
    }

    private func complete() {
        for (index, preset) in selectedPresets.enumerated() {
            _ = habitService.create(from: preset, displayOrder: index)
        }
        settingsService.hasCompletedOnboarding = true
    }
}
