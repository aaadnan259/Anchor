import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(SettingsService.self) private var settingsService
    @Query(filter: #Predicate<Habit> { !$0.archived }, sort: \Habit.displayOrder) private var habits: [Habit]

    @State private var viewModel: TodayViewModel?
    @State private var isShowingSettings = false
    @State private var loggingTarget: LoggingTarget?
    @State private var showCompletionCelebration = false

    private let today = Date.now

    private struct LoggingTarget: Identifiable {
        let habit: Habit
        let occurrence: Occurrence
        var id: UUID { occurrence.id }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel {
                    let rows = viewModel.rows(for: habits, on: today)
                    let progress = viewModel.overallProgress(for: rows)

                    header(progress: progress)
                        .onChange(of: progress) { oldValue, newValue in
                            if newValue >= 1 && oldValue < 1 {
                                showCompletionCelebration = true
                            }
                        }

                    if rows.isEmpty {
                        emptyState
                        Spacer()
                    } else {
                        habitList(rows: rows, viewModel: viewModel)
                    }
                } else {
                    header(progress: 0)
                    Spacer()
                }
            }
            .background(Surface.background)
            .navigationBarHidden(true)
            .task {
                if viewModel == nil {
                    viewModel = makeViewModel()
                }
            }
            .task(id: showCompletionCelebration) {
                guard showCompletionCelebration else { return }
                try? await Task.sleep(for: .seconds(1.1))
                showCompletionCelebration = false
            }
            .onChange(of: settingsService.calculationMethod) { viewModel = makeViewModel() }
            .onChange(of: settingsService.madhab) { viewModel = makeViewModel() }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(item: $loggingTarget) { target in
                if let viewModel {
                    LogValueView(habit: target.habit, occurrence: target.occurrence, viewModel: viewModel, date: today)
                }
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
                tint: settingsService.effectiveAccentColor,
                size: 56,
                accessibilityLabelText: "Today's overall progress",
                pulseGlow: true
            )
            .overlay {
                if showCompletionCelebration {
                    CompletionCelebrationView(tint: settingsService.effectiveAccentColor)
                }
            }
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
        .padding(.top, Spacing.base)
        .padding(.bottom, Spacing.sm)
    }

    private func habitList(rows: [TodayViewModel.TodayHabitRow], viewModel: TodayViewModel) -> some View {
        List {
            Section {
                ForEach(rows) { row in
                    habitRow(row: row, viewModel: viewModel)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(rowInsets)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(row.habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                SectionHeaderView(title: "Today")
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: Spacing.xs, leading: Spacing.base, bottom: Spacing.xs, trailing: Spacing.base)
    }

    @ViewBuilder
    private func habitRow(row: TodayViewModel.TodayHabitRow, viewModel: TodayViewModel) -> some View {
        let isExpanded = viewModel.expandedHabitIDs.contains(row.habit.id)
        let isQuantifiable = !row.isExpandable && row.habit.targetValue != nil

        VStack(spacing: Spacing.sm) {
            HabitCardView(
                icon: row.habit.icon,
                title: row.habit.name,
                subtitle: (row.isExpandable && isExpanded) ? nil : row.subtitle,
                tint: row.habit.tintColor,
                streak: row.streak,
                isCompleted: row.isFullyCompleted,
                progress: row.isExpandable ? row.progress : (isQuantifiable ? viewModel.quantifiableProgress(for: row, on: today) : nil),
                isExpandable: row.isExpandable,
                isExpanded: isExpanded,
                isQuantifiable: isQuantifiable,
                isShielded: viewModel.isShielded(habit: row.habit, on: today),
                supportsShields: row.habit.frequency.supportsShields,
                onToggleCompletion: {
                    if let only = row.due.first {
                        viewModel.toggle(habit: row.habit, occurrence: only.occurrence, on: today)
                    }
                },
                onTapExpand: {
                    viewModel.toggleExpanded(row.habit.id)
                },
                onTapLogValue: {
                    if let occurrence = row.due.first?.occurrence {
                        loggingTarget = LoggingTarget(habit: row.habit, occurrence: occurrence)
                    }
                },
                onToggleShield: {
                    viewModel.toggleShield(habit: row.habit, on: today)
                }
            )

            if row.isExpandable && isExpanded {
                VStack(spacing: 0) {
                    ForEach(row.due, id: \.occurrence.id) { due in
                        OccurrenceRowView(
                            title: due.occurrence.title,
                            timeLabel: due.time?.formatted(date: .omitted, time: .shortened),
                            isCompleted: viewModel.isCompleted(occurrence: due.occurrence, on: today),
                            tint: row.habit.tintColor,
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
        .padding(.vertical, Spacing.xs)
    }

    private var emptyState: some View {
        Group {
            if habits.isEmpty {
                ContentUnavailableView("No Habits Yet", systemImage: "checkmark.circle", description: Text("Add a habit to get started."))
            } else {
                ContentUnavailableView("Nothing Due Today", systemImage: "checkmark.circle", description: Text("Nothing scheduled for today. Check back tomorrow."))
            }
        }
        .padding(.top, Spacing.xxl)
    }

    private func makeViewModel() -> TodayViewModel {
        let completionService = CompletionService(context: modelContext)
        let prayerService = PrayerService(calculationMethod: settingsService.calculationMethod, madhab: settingsService.madhab)
        let scheduleService = ScheduleService(prayerService: prayerService, locationService: locationService)
        let streakService = StreakService(completionService: completionService)
        return TodayViewModel(
            habitService: HabitService(context: modelContext),
            scheduleService: scheduleService,
            completionService: completionService,
            streakService: streakService,
            notificationService: NotificationService(),
            smartRemindersEnabled: settingsService.smartRemindersEnabled
        )
    }
}
