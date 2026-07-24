import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var icon: String
    var accentColor: AccentColor
    var reminderEnabled: Bool
    var archived: Bool
    var createdAt: Date
    var displayOrder: Int

    private var frequencyData: Data

    var frequency: Frequency {
        get { (try? JSONDecoder().decode(Frequency.self, from: frequencyData)) ?? .daily }
        set { frequencyData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    @Relationship(deleteRule: .cascade, inverse: \Occurrence.habit)
    var occurrences: [Occurrence] = []

    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion] = []

    @Relationship(deleteRule: .cascade, inverse: \Shield.habit)
    var shields: [Shield] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        accentColor: AccentColor,
        frequency: Frequency,
        reminderEnabled: Bool = false,
        archived: Bool = false,
        createdAt: Date = .now,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.accentColor = accentColor
        self.frequencyData = (try? JSONEncoder().encode(frequency)) ?? Data()
        self.reminderEnabled = reminderEnabled
        self.archived = archived
        self.createdAt = createdAt
        self.displayOrder = displayOrder
    }
}
