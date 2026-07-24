import Foundation
import SwiftData

@Model
final class Shield {
    var id: UUID
    var day: Date

    var habit: Habit?

    init(
        id: UUID = UUID(),
        habit: Habit,
        day: Date
    ) {
        self.id = id
        self.habit = habit
        self.day = day
    }
}
