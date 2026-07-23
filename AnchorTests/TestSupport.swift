import Foundation
import SwiftData
import Testing
@testable import Anchor

@MainActor
enum TestSupport {
    static func makeContext() throws -> ModelContext {
        let schema = Schema([Habit.self, Occurrence.self, Completion.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }

    nonisolated static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2 // Monday
        return calendar
    }

    nonisolated static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}
