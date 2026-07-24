import SwiftUI

struct ManageShieldsView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    let viewModel: HabitInsightsViewModel

    @State private var selectedDate = Date.now

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: habit.createdAt...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(habit.accentColor.color)
                    .listRowSeparator(.hidden)

                    PrimaryButtonView(
                        title: isSelectedDateShielded ? "Remove Shield" : "Shield This Day",
                        tint: habit.accentColor.color
                    ) {
                        viewModel.toggleShield(habit: habit, on: selectedDate)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                if !shieldedDays.isEmpty {
                    Section("Shielded Days") {
                        ForEach(shieldedDays, id: \.self) { day in
                            Text(day.formatted(date: .abbreviated, time: .omitted))
                                .font(.anchorBody)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.toggleShield(habit: habit, on: day)
                                    } label: {
                                        Label("Remove", systemImage: "shield.slash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Shielded Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var isSelectedDateShielded: Bool {
        viewModel.isShielded(habit: habit, on: selectedDate)
    }

    private var shieldedDays: [Date] {
        viewModel.shieldedDays(for: habit)
    }
}
