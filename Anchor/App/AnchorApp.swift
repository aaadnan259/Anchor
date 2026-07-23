import SwiftUI
import SwiftData

@main
struct AnchorApp: App {
    private let container: ModelContainer
    @State private var locationService = LocationService()
    @State private var settingsService = SettingsService()

    init() {
        container = Self.isRunningTests ? Self.makeInMemoryContainer() : Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            if Self.isRunningTests {
                Color.clear
            } else {
                RootTabView()
                    .preferredColorScheme(settingsService.appearance.colorScheme)
            }
        }
        .modelContainer(container)
        .environment(locationService)
        .environment(settingsService)
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([Habit.self, Occurrence.self, Completion.self])
        guard let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ) else {
            preconditionFailure("Failed to create in-memory ModelContainer for tests")
        }
        return container
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Habit.self, Occurrence.self, Completion.self])

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
