import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.displayOrder) private var allHabits: [Habit]

    @State private var viewModel: StatsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    let stats = viewModel.stats(for: allHabits)
                    if stats.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(spacing: Spacing.md) {
                                ForEach(stats) { stat in
                                    NavigationLink {
                                        HabitInsightsView(habit: stat.habit)
                                    } label: {
                                        statCard(stat)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(Spacing.base)
                        }
                        .background(Surface.background)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Stats")
            .task {
                if viewModel == nil {
                    viewModel = StatsViewModel(
                        streakService: StreakService(completionService: CompletionService(context: modelContext))
                    )
                }
            }
        }
    }

    private func statCard(_ stat: StatsViewModel.HabitStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(stat.habit.tintColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .stroke(stat.habit.tintColor.opacity(0.35), lineWidth: 1)
                        )
                    HabitIconView(icon: stat.habit.icon)
                        .foregroundStyle(stat.habit.tintColor)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.habit.name)
                        .font(.anchorHeadline)
                    Text("\(Int(stat.completionRate * 100))% complete")
                        .font(.anchorFootnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                WeeklyBarsView(rates: stat.weeklyRates, tint: stat.habit.tintColor)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Spacing.lg) {
                statBadge(icon: "flame.fill", label: "Current", value: stat.currentStreak, tint: .orange)
                statBadge(icon: "trophy.fill", label: "Best", value: stat.bestStreak, tint: stat.habit.tintColor)
            }

            HabitHistoryGridView(days: stat.history, tint: stat.habit.tintColor)
        }
        .padding(Spacing.base)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .fill(Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                .stroke(Surface.border, lineWidth: 1)
        )
    }

    private func statBadge(icon: String, label: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.caption)
                Text("\(value)")
                    .font(.anchorNumeric)
            }
            Text(label)
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        ContentUnavailableView("No Stats Yet", systemImage: "chart.bar.fill", description: Text("Complete a habit to start building streaks."))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Surface.background)
    }
}
