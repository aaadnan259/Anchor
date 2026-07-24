import SwiftUI
import SwiftData

struct AddEditHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var locationService
    @Environment(SettingsService.self) private var settingsService
    @Query private var allHabits: [Habit]

    let habit: Habit?

    @State private var viewModel: AddEditHabitViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    form(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(habit == nil ? "Add Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel?.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel?.isSaveDisabled ?? true)
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = AddEditHabitViewModel(
                        habitService: HabitService(context: modelContext),
                        habit: habit,
                        nextDisplayOrder: allHabits.count,
                        notificationService: NotificationService(),
                        scheduleService: ScheduleService(
                            prayerService: PrayerService(calculationMethod: settingsService.calculationMethod, madhab: settingsService.madhab),
                            locationService: locationService
                        ),
                        locationService: locationService,
                        completionService: CompletionService(context: modelContext),
                        smartRemindersEnabled: settingsService.smartRemindersEnabled
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func form(viewModel: AddEditHabitViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if habit == nil {
                    presetSection(viewModel: viewModel)
                }

                nameSection(viewModel: viewModel)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionHeaderView(title: "Icon")
                    IconPickerView(selection: Bindable(viewModel).icon, tint: viewModel.accentColor.color)
                        .padding(.horizontal, Spacing.base)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionHeaderView(title: "Color")
                    AccentColorPickerView(selection: Bindable(viewModel).accentColor)
                        .padding(.horizontal, Spacing.base)
                }

                frequencySection(viewModel: viewModel)
                if viewModel.occurrenceMode == .single {
                    quantifiableSection(viewModel: viewModel)
                }
                reminderSection(viewModel: viewModel)
            }
            .padding(.vertical, Spacing.base)
        }
        .background(Surface.background)
    }

    private func presetSection(viewModel: AddEditHabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Quick Start")
            HStack(spacing: Spacing.sm) {
                ForEach(HabitPreset.all) { preset in
                    PresetCardView(icon: preset.icon, title: preset.title, tint: preset.accentColor.color) {
                        viewModel.applyPreset(preset)
                    }
                }
                PresetCardView(icon: "square.and.pencil", title: "Custom", tint: .secondary) {
                    viewModel.applyCustom()
                }
            }
            .padding(.horizontal, Spacing.base)
        }
    }

    private func nameSection(viewModel: AddEditHabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Name")
            TextField("Habit name", text: Bindable(viewModel).name)
                .font(.anchorBody)
                .padding(Spacing.base)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(Surface.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .stroke(Surface.border, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.base)
        }
    }

    private func frequencySection(viewModel: AddEditHabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Frequency")

            Picker("Frequency", selection: Bindable(viewModel).frequencyKind) {
                ForEach(AddEditHabitViewModel.FrequencyKind.allCases) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.base)

            switch viewModel.frequencyKind {
            case .daily:
                EmptyView()
            case .weekdays:
                weekdaySelector(viewModel: viewModel)
            case .timesPerWeek:
                Stepper("\(viewModel.timesPerWeekTarget)x per week", value: Bindable(viewModel).timesPerWeekTarget, in: 1...7)
                    .font(.anchorBody)
                    .padding(Spacing.base)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .fill(Surface.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .stroke(Surface.border, lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.base)
            }
        }
    }

    private func weekdaySelector(viewModel: AddEditHabitViewModel) -> some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Weekday.allCases) { day in
                let isSelected = viewModel.selectedWeekdays.contains(day)
                Button {
                    Haptics.light()
                    if isSelected {
                        viewModel.selectedWeekdays.remove(day)
                    } else {
                        viewModel.selectedWeekdays.insert(day)
                    }
                } label: {
                    Text(day.shortLabel.prefix(1))
                        .font(.anchorCaption.weight(.semibold))
                        .frame(width: 40, height: 40)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .background(Circle().fill(isSelected ? viewModel.accentColor.color : Surface.card))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.shortLabel)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, Spacing.base)
    }

    private func quantifiableSection(viewModel: AddEditHabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Tracking")
            VStack(spacing: 0) {
                Toggle("Track a Number", isOn: Bindable(viewModel).isQuantifiable)
                    .font(.anchorBody)
                    .padding(Spacing.base)

                if viewModel.isQuantifiable {
                    Divider().padding(.horizontal, Spacing.base)
                    Stepper("Target: \(viewModel.targetValue)", value: Bindable(viewModel).targetValue, in: 1...999)
                        .font(.anchorBody)
                        .padding(Spacing.base)

                    Divider().padding(.horizontal, Spacing.base)
                    TextField("Unit (e.g. glasses)", text: Bindable(viewModel).unitLabel)
                        .font(.anchorBody)
                        .padding(Spacing.base)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.base)

            Text("Log a number each day instead of a simple checkmark, like glasses of water or pages read.")
                .font(.anchorFootnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.base)
        }
    }

    private func reminderSection(viewModel: AddEditHabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Reminder")
            VStack(spacing: 0) {
                Toggle(
                    viewModel.occurrenceMode == .prayer ? "Prayer time notifications" : "Remind me",
                    isOn: Bindable(viewModel).reminderEnabled
                )
                .font(.anchorBody)
                .padding(Spacing.base)

                if viewModel.reminderEnabled && viewModel.occurrenceMode == .single {
                    Divider().padding(.horizontal, Spacing.base)
                    DatePicker("Time", selection: Bindable(viewModel).reminderTime, displayedComponents: .hourAndMinute)
                        .font(.anchorBody)
                        .padding(Spacing.base)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Surface.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .stroke(Surface.border, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.base)
        }
    }
}
