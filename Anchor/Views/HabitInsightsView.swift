import SwiftUI
import SwiftData

struct HabitInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit

    @State private var viewModel: HabitInsightsViewModel?
    @State private var isPresentingShieldSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                if let viewModel {
                    let hasAnyCompletions = viewModel.timeOfDaySlices(for: habit).contains { $0.count > 0 }
                    trendSection(viewModel: viewModel, hasAnyCompletions: hasAnyCompletions)
                    timeOfDaySection(viewModel: viewModel, hasAnyCompletions: hasAnyCompletions)
                    historySection(viewModel: viewModel)
                }
            }
            .padding(.vertical, Spacing.base)
        }
        .background(Surface.background)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let completionService = CompletionService(context: modelContext)
                let streakService = StreakService(completionService: completionService)
                viewModel = HabitInsightsViewModel(
                    insightsService: InsightsService(completionService: completionService, streakService: streakService),
                    streakService: streakService,
                    completionService: completionService
                )
            }
        }
        .sheet(isPresented: $isPresentingShieldSheet) {
            if let viewModel {
                ManageShieldsView(habit: habit, viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(habit.tintColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .stroke(habit.tintColor.opacity(0.35), lineWidth: 1)
                    )
                HabitIconView(icon: habit.icon)
                    .foregroundStyle(habit.tintColor)
            }
            .frame(width: 44, height: 44)

            Text(habit.name)
                .font(.anchorTitle)

            Spacer()
        }
        .padding(.horizontal, Spacing.base)
        .accessibilityElement(children: .combine)
    }

    private func trendSection(viewModel: HabitInsightsViewModel, hasAnyCompletions: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Trend")

            Picker("Range", selection: Bindable(viewModel).selectedRange) {
                ForEach(InsightsRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.base)

            Group {
                if hasAnyCompletions {
                    TrendChartView(
                        points: viewModel.trendPoints(for: habit),
                        range: viewModel.selectedRange,
                        tint: habit.tintColor
                    )
                } else {
                    ContentUnavailableView(
                        "Not Enough Data Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete this habit a few times to see trends here.")
                    )
                    .frame(height: 180)
                }
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
            .padding(.horizontal, Spacing.base)
        }
    }

    private func timeOfDaySection(viewModel: HabitInsightsViewModel, hasAnyCompletions: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Time of Day")

            Group {
                if hasAnyCompletions {
                    TimeOfDayChartView(slices: viewModel.timeOfDaySlices(for: habit), tint: habit.tintColor)
                } else {
                    ContentUnavailableView(
                        "No Completions Yet",
                        systemImage: "clock",
                        description: Text("Complete this habit to see when you usually do it.")
                    )
                    .frame(height: 140)
                }
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
            .padding(.horizontal, Spacing.base)
        }
    }

    private func historySection(viewModel: HabitInsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "History")

            VStack(spacing: 0) {
                HabitHistoryGridView(days: viewModel.dailyHistory(for: habit), tint: habit.tintColor)
                    .padding(Spacing.base)

                if habit.frequency.supportsShields {
                    Divider().padding(.horizontal, Spacing.base)
                    Button {
                        isPresentingShieldSheet = true
                    } label: {
                        HStack {
                            Text("Manage Shielded Days")
                                .font(.anchorBody)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "shield.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(Spacing.base)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.base)

            if habit.frequency.supportsShields {
                Text("Shield a day to protect your streak — for vacation, illness, or any day you can't complete this habit.")
                    .font(.anchorFootnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.base)
            }
        }
    }
}
