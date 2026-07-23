import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(SettingsService.self) private var settingsService
    @Query(sort: \Habit.displayOrder) private var allHabits: [Habit]

    @State private var viewModel: HabitsViewModel?
    @State private var habitToEdit: Habit?
    @State private var isPresentingAdd = false

    private var activeHabits: [Habit] { allHabits.filter { !$0.archived } }
    private var archivedHabits: [Habit] { allHabits.filter { $0.archived } }

    var body: some View {
        NavigationStack {
            Group {
                if activeHabits.isEmpty && archivedHabits.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Habit")
                }
                if !activeHabits.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
            .task {
                if viewModel == nil {
                    let completionService = CompletionService(context: modelContext)
                    viewModel = HabitsViewModel(
                        habitService: HabitService(context: modelContext),
                        streakService: StreakService(completionService: completionService),
                        notificationService: NotificationService(),
                        scheduleService: ScheduleService(
                            prayerService: PrayerService(calculationMethod: settingsService.calculationMethod, madhab: settingsService.madhab),
                            locationService: locationService
                        ),
                        completionService: completionService,
                        smartRemindersEnabled: settingsService.smartRemindersEnabled
                    )
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddEditHabitView(habit: nil)
            }
            .sheet(item: $habitToEdit) { habit in
                AddEditHabitView(habit: habit)
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(activeHabits) { habit in
                    habitRow(habit)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(rowInsets)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel?.delete(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                viewModel?.archive(habit)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                }
                .onMove(perform: move)
            } header: {
                SectionHeaderView(title: "Habits")
                    .listRowInsets(EdgeInsets())
            }

            if !archivedHabits.isEmpty {
                Section {
                    ForEach(archivedHabits) { habit in
                        habitRow(habit, isArchived: true)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(rowInsets)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel?.delete(habit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    viewModel?.unarchive(habit)
                                } label: {
                                    Label("Unarchive", systemImage: "arrow.uturn.up")
                                }
                                .tint(.blue)
                            }
                    }
                } header: {
                    SectionHeaderView(title: "Archived")
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Surface.background)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: Spacing.xs, leading: Spacing.base, bottom: Spacing.xs, trailing: Spacing.base)
    }

    private func habitRow(_ habit: Habit, isArchived: Bool = false) -> some View {
        Button {
            habitToEdit = habit
        } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(habit.accentColor.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .stroke(habit.accentColor.color.opacity(0.35), lineWidth: 1)
                        )
                    Image(systemName: habit.icon)
                        .foregroundStyle(habit.accentColor.color)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.anchorHeadline)
                        .foregroundStyle(.primary)
                    Text(viewModel?.frequencyDescription(for: habit) ?? "")
                        .font(.anchorFootnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isArchived, let streak = viewModel?.streak(for: habit), streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.caption)
                        Text("\(streak)").font(.anchorNumeric)
                    }
                    .foregroundStyle(.orange)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(streak) day streak")
                }
            }
            .padding(Spacing.base)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .fill(Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Surface.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No habits yet")
                .font(.anchorHeadline)
            Text("Tap + to add your first habit.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Surface.background)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)
        viewModel?.reorder(reordered)
    }
}
