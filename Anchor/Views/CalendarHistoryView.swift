import SwiftUI

struct CalendarHistoryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let habit: Habit
    let viewModel: HabitInsightsViewModel

    @State private var displayedMonth: Date = .now

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                monthHeader

                CalendarHistoryGridView(month: displayedMonth, tint: habit.tintColor) { date in
                    viewModel.dayCompletionState(for: habit, on: date)
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
            .padding(.vertical, Spacing.base)
        }
        .background(Surface.background)
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoToPreviousMonth)
            .opacity(canGoToPreviousMonth ? 1 : 0.3)
            .accessibilityLabel("Previous month")

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.anchorHeadline)

            Spacer()

            Button {
                goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoToNextMonth)
            .opacity(canGoToNextMonth ? 1 : 0.3)
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, Spacing.base)
    }

    private func goToPreviousMonth() {
        guard canGoToPreviousMonth, let previous = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        withAnimation(reduceMotion ? .linear(duration: 0.1) : Motion.snappy) {
            displayedMonth = previous
        }
    }

    private func goToNextMonth() {
        guard canGoToNextMonth, let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        withAnimation(reduceMotion ? .linear(duration: 0.1) : Motion.snappy) {
            displayedMonth = next
        }
    }

    private var displayedMonthStart: Date {
        calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
    }

    private var currentMonthStart: Date {
        calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var habitCreationMonthStart: Date {
        calendar.dateInterval(of: .month, for: habit.createdAt)?.start ?? habit.createdAt
    }

    private var canGoToNextMonth: Bool {
        displayedMonthStart < currentMonthStart
    }

    private var canGoToPreviousMonth: Bool {
        displayedMonthStart > habitCreationMonthStart
    }
}
