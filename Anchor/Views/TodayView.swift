import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(SettingsService.self) private var settingsService
    @Query(filter: #Predicate<Habit> { !$0.archived }, sort: \Habit.displayOrder) private var habits: [Habit]

    @State private var viewModel: TodayViewModel?
    @State private var isShowingSettings = false

    private let today = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let viewModel {
                        let rows = viewModel.rows(for: habits, on: today)
                        header(progress: viewModel.overallProgress(for: rows))

                        if rows.isEmpty {
                            emptyState
                        } else {
                            habitList(rows: rows, viewModel: viewModel)
                        }
                    } else {
                        header(progress: 0)
                    }
                }
                .padding(.vertical, Spacing.base)
            }
            .background(Surface.background)
            .navigationBarHidden(true)
            .task {
                if viewModel == nil {
                    viewModel = makeViewModel()
                }
            }
            .onChange(of: settingsService.calculationMethod) { viewModel = makeViewModel() }
            .onChange(of: settingsService.madhab) { viewModel = makeViewModel() }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private func header(progress: Double) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(today.formatted(.dateTime.weekday(.wide)))
                    .font(.anchorLargeTitle)
                    .tracking(-0.5)
                Text(today.formatted(.dateTime.month(.wide).day()))
                    .font(.anchorSubheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            ProgressRingView(
                progress: progress,
                tint: AccentColor.indigo.color,
                size: 56,
                accessibilityLabelText: "Today's overall progress"
            )
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, Spacing.base)
    }

    private func habitList(rows: [TodayViewModel.TodayHabitRow], viewModel: TodayViewModel) -> some View {
        VStack(spacing: Spacing.md) {
            SectionHeaderView(title: "Today")

            ForEach(rows) { row in
                let isExpanded = viewModel.expandedHabitIDs.contains(row.habit.id)

                HabitCardView(
                    icon: row.habit.icon,
                    title: row.habit.name,
                    subtitle: (row.isExpandable && isExpanded) ? nil : row.subtitle,
                    tint: row.habit.accentColor.color,
                    streak: row.streak,
                    isCompleted: row.isFullyCompleted,
                    progress: row.isExpandable ? row.progress : nil,
                    isExpandable: row.isExpandable,
                    isExpanded: isExpanded,
                    onToggleCompletion: {
                        if let only = row.due.first {
                            viewModel.toggle(habit: row.habit, occurrence: only.occurrence, on: today)
                        }
                    },
                    onTapExpand: {
                        viewModel.toggleExpanded(row.habit.id)
                    }
                )

                if row.isExpandable && isExpanded {
                    VStack(spacing: 0) {
                        ForEach(row.due, id: \.occurrence.id) { due in
                            OccurrenceRowView(
                                title: due.occurrence.title,
                                timeLabel: due.time?.formatted(date: .omitted, time: .shortened),
                                isCompleted: viewModel.isCompleted(occurrence: due.occurrence, on: today),
                                tint: row.habit.accentColor.color,
                                onToggleCompletion: {
                                    viewModel.toggle(habit: row.habit, occurrence: due.occurrence, on: today)
                                }
                            )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                            .fill(Surface.card.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                            .stroke(Surface.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, Spacing.base)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Nothing due today")
                .font(.anchorHeadline)
            Text("Habits you add will show up here.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }

    private func makeViewModel() -> TodayViewModel {
        let completionService = CompletionService(context: modelContext)
        let prayerService = PrayerService(calculationMethod: settingsService.calculationMethod, madhab: settingsService.madhab)
        let scheduleService = ScheduleService(prayerService: prayerService, locationService: locationService)
        let streakService = StreakService(completionService: completionService)
        return TodayViewModel(
            scheduleService: scheduleService,
            completionService: completionService,
            streakService: streakService
        )
    }
}
