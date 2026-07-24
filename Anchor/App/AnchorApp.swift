import SwiftUI
import SwiftData
import UIKit

@main
struct AnchorApp: App {
    private let container: ModelContainer
    @State private var locationService = LocationService()
    @State private var settingsService = SettingsService()
    @State private var isUnlocked = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        container = Self.isRunningTests ? Self.makeInMemoryContainer() : Self.makeContainer()
        Self.configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            if Self.isRunningTests {
                Color.clear
            } else if !settingsService.hasCompletedOnboarding {
                OnboardingView()
                    .preferredColorScheme(settingsService.appearance.colorScheme)
            } else if settingsService.biometricLockEnabled && !isUnlocked {
                LockScreenView(isUnlocked: $isUnlocked)
                    .preferredColorScheme(settingsService.appearance.colorScheme)
            } else {
                RootTabView()
                    .preferredColorScheme(settingsService.appearance.colorScheme)
            }
        }
        .modelContainer(container)
        .environment(locationService)
        .environment(settingsService)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && settingsService.biometricLockEnabled {
                isUnlocked = false
            }
        }
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// SwiftUI's TabView renders unselected tab icons noticeably dim in dark mode; bump them
    /// to `.secondaryLabel` for better legibility. Only UIKit-appearance-proxy code in the app.
    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([Habit.self, Occurrence.self, Completion.self, Shield.self])
        guard let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) else {
            preconditionFailure("Failed to create in-memory ModelContainer for tests")
        }
        return container
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Habit.self, Occurrence.self, Completion.self, Shield.self])

        if let onDisk = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)]) {
            return onDisk
        }

        guard let inMemory = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) else {
            preconditionFailure("Failed to create both on-disk and in-memory ModelContainer")
        }
        return inMemory
    }
}
