import Foundation
import SwiftData

@Model
final class Completion {
    var id: UUID
    var day: Date
    var completedAt: Date
    var value: Int

    var habit: Habit?
    var occurrence: Occurrence?

    init(
        id: UUID = UUID(),
        habit: Habit,
        occurrence: Occurrence,
        day: Date,
        completedAt: Date = .now,
        value: Int = 1
    ) {
        self.id = id
        self.habit = habit
        self.occurrence = occurrence
        self.day = day
        self.completedAt = completedAt
        self.value = value
    }
}
