import Foundation
import SwiftData
import SwiftUI

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
    var targetValue: Int?
    var unit: String?
    var customColorHex: UInt?

    private var frequencyData: Data

    var frequency: Frequency {
        get { (try? JSONDecoder().decode(Frequency.self, from: frequencyData)) ?? .daily }
        set { frequencyData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// This habit's effective tint: an exact custom color when set, otherwise the curated `accentColor`.
    var tintColor: Color {
        customColorHex.map { Color(hex: $0) } ?? accentColor.color
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
        displayOrder: Int = 0,
        targetValue: Int? = nil,
        unit: String? = nil,
        customColorHex: UInt? = nil
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
        self.targetValue = targetValue
        self.unit = unit
        self.customColorHex = customColorHex
    }
}
