import SwiftUI
import SwiftData

struct HabitInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit

    @State private var viewModel: HabitInsightsViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                if let viewModel {
                    trendSection(viewModel: viewModel)
                    timeOfDaySection(viewModel: viewModel)
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
                    insightsService: InsightsService(completionService: completionService, streakService: streakService)
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.md) {
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
            .frame(width: 44, height: 44)

            Text(habit.name)
                .font(.anchorTitle)

            Spacer()
        }
        .padding(.horizontal, Spacing.base)
        .accessibilityElement(children: .combine)
    }

    private func trendSection(viewModel: HabitInsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Trend")

            Picker("Range", selection: Bindable(viewModel).selectedRange) {
                ForEach(InsightsRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.base)

            TrendChartView(
                points: viewModel.trendPoints(for: habit),
                range: viewModel.selectedRange,
                tint: habit.accentColor.color
            )
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

    private func timeOfDaySection(viewModel: HabitInsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Time of Day")

            TimeOfDayChartView(slices: viewModel.timeOfDaySlices(for: habit), tint: habit.accentColor.color)
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
}
