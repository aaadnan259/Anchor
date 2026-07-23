import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(SettingsService.self) private var settingsService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "list.bullet") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
        .tint(settingsService.accentColor.color)
        .task {
            await refreshAndReschedule()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await refreshAndReschedule() }
            }
        }
    }

    private func refreshAndReschedule() async {
        await locationService.refreshLocation()

        let habitService = HabitService(context: modelContext)
        let prayerService = PrayerService(calculationMethod: settingsService.calculationMethod, madhab: settingsService.madhab)
        let scheduleService = ScheduleService(prayerService: prayerService, locationService: locationService)
        let notificationService = NotificationService()
        await notificationService.rescheduleAll(for: habitService.fetchAll(), scheduleService: scheduleService)
    }
}
