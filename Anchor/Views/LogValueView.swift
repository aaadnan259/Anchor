import SwiftUI

struct LogValueView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    let occurrence: Occurrence
    let viewModel: TodayViewModel
    let date: Date

    @State private var value: Int

    init(habit: Habit, occurrence: Occurrence, viewModel: TodayViewModel, date: Date) {
        self.habit = habit
        self.occurrence = occurrence
        self.viewModel = viewModel
        self.date = date
        self._value = State(initialValue: viewModel.value(for: occurrence, on: date))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Spacer()

                VStack(spacing: Spacing.sm) {
                    Text("\(value)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(habit.accentColor.color)
                    if let target = habit.targetValue {
                        Text("of \(target)\(habit.unit.map { " \($0)" } ?? "")")
                            .font(.anchorBody)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)

                Stepper("Amount", value: $value, in: 0...999)
                    .labelsHidden()
                    .onChange(of: value) { _, newValue in
                        viewModel.logValue(habit: habit, occurrence: occurrence, value: newValue, on: date)
                    }

                Spacer()
                Spacer()
            }
            .padding(Spacing.lg)
            .background(Surface.background)
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
