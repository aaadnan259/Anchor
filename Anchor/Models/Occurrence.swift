import Foundation
import SwiftData

@Model
final class Occurrence {
    var id: UUID
    var title: String
    var displayOrder: Int

    private var scheduleProviderData: Data

    var scheduleProvider: ScheduleProviderKind {
        get { (try? JSONDecoder().decode(ScheduleProviderKind.self, from: scheduleProviderData)) ?? .unscheduled }
        set { scheduleProviderData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var habit: Habit?

    @Relationship(deleteRule: .cascade, inverse: \Completion.occurrence)
    var completions: [Completion] = []

    init(
        id: UUID = UUID(),
        title: String,
        displayOrder: Int = 0,
        scheduleProvider: ScheduleProviderKind = .unscheduled
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.scheduleProviderData = (try? JSONEncoder().encode(scheduleProvider)) ?? Data()
    }
}
