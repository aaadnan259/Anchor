import Foundation
import CoreLocation
import Testing
@testable import Anchor

@Suite("ScheduleProvider strategies")
struct ScheduleProviderTests {
    private let calendar = TestSupport.calendar

    @Test("FixedTimeProvider computes the correct time")
    func fixedTimeProviderComputesTime() throws {
        let habit = Habit(name: "Meditate", icon: "brain.head.profile", accentColor: .indigo, frequency: .daily, displayOrder: 0)
        let occurrence = Occurrence(title: "Meditate", displayOrder: 0, scheduleProvider: .fixedTime(hour: 20, minute: 30))
        habit.occurrences = [occurrence]

        let date = try TestSupport.date(2026, 7, 22)
        let result = FixedTimeProvider().schedule(habit: habit, occurrence: occurrence, on: date, calendar: calendar)

        let time = try #require(result?.time)
        let components = calendar.dateComponents([.hour, .minute], from: time)
        #expect(components.hour == 20)
        #expect(components.minute == 30)
    }

    @Test("FixedTimeProvider returns nil for the wrong schedule kind")
    func fixedTimeProviderWrongKind() throws {
        let habit = Habit(name: "Gym", icon: "dumbbell.fill", accentColor: .coral, frequency: .daily, displayOrder: 0)
        let occurrence = Occurrence(title: "Gym", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]

        let date = try TestSupport.date(2026, 7, 22)
        let result = FixedTimeProvider().schedule(habit: habit, occurrence: occurrence, on: date, calendar: calendar)
        #expect(result == nil)
    }

    @Test("WeeklyProvider is due on matching weekday and not on others")
    func weeklyProviderRespectsWeekday() throws {
        let habit = Habit(
            name: "Work",
            icon: "briefcase.fill",
            accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            displayOrder: 0
        )
        let occurrence = Occurrence(title: "Work", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]

        let wednesday = try TestSupport.date(2026, 7, 22)
        let saturday = try TestSupport.date(2026, 7, 25)

        let dueResult = WeeklyProvider().schedule(habit: habit, occurrence: occurrence, on: wednesday, calendar: calendar)
        let notDueResult = WeeklyProvider().schedule(habit: habit, occurrence: occurrence, on: saturday, calendar: calendar)

        #expect(dueResult != nil)
        #expect(dueResult?.time == nil)
        #expect(notDueResult == nil)
    }

    @Test("PrayerProvider returns a computed time when a coordinate is available")
    func prayerProviderReturnsTimeWithCoordinate() throws {
        let habit = Habit(name: "Prayer", icon: "moon.stars.fill", accentColor: .violet, frequency: .daily, displayOrder: 0)
        let occurrence = Occurrence(title: "Fajr", displayOrder: 0, scheduleProvider: .prayer(.fajr))
        habit.occurrences = [occurrence]

        let provider = PrayerProvider(
            prayerService: PrayerService(),
            coordinate: CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
        )
        let date = try TestSupport.date(2026, 7, 22)
        let result = provider.schedule(habit: habit, occurrence: occurrence, on: date, calendar: calendar)

        #expect(result != nil)
        #expect(result?.time != nil)
    }

    @Test("PrayerProvider is still due but has no time without a coordinate")
    func prayerProviderNoTimeWithoutCoordinate() throws {
        let habit = Habit(name: "Prayer", icon: "moon.stars.fill", accentColor: .violet, frequency: .daily, displayOrder: 0)
        let occurrence = Occurrence(title: "Fajr", displayOrder: 0, scheduleProvider: .prayer(.fajr))
        habit.occurrences = [occurrence]

        let provider = PrayerProvider(prayerService: PrayerService(), coordinate: nil)
        let date = try TestSupport.date(2026, 7, 22)
        let result = provider.schedule(habit: habit, occurrence: occurrence, on: date, calendar: calendar)

        #expect(result != nil)
        #expect(result?.time == nil)
    }
}

@MainActor
@Suite("ScheduleService")
struct ScheduleServiceTests {
    private let calendar = TestSupport.calendar

    @Test("returns due occurrences sorted by display order")
    func returnsDueOccurrencesSorted() throws {
        let habit = Habit(name: "Prayer", icon: "moon.stars.fill", accentColor: .violet, frequency: .daily, displayOrder: 0)
        let second = Occurrence(title: "Second", displayOrder: 1, scheduleProvider: .fixedTime(hour: 12, minute: 0))
        let first = Occurrence(title: "First", displayOrder: 0, scheduleProvider: .fixedTime(hour: 8, minute: 0))
        habit.occurrences = [second, first]

        let service = ScheduleService(prayerService: PrayerService(), locationService: LocationService())
        let date = try TestSupport.date(2026, 7, 22)
        let result = service.todaysOccurrences(for: habit, on: date, calendar: calendar)

        #expect(result.count == 2)
        #expect(result.first?.occurrence.title == "First")
    }

    @Test("excludes occurrences on non-due weekdays")
    func excludesNonDueWeekdays() throws {
        let habit = Habit(
            name: "Work",
            icon: "briefcase.fill",
            accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            displayOrder: 0
        )
        habit.occurrences = [Occurrence(title: "Work", displayOrder: 0, scheduleProvider: .unscheduled)]

        let service = ScheduleService(prayerService: PrayerService(), locationService: LocationService())
        let saturday = try TestSupport.date(2026, 7, 25)
        let result = service.todaysOccurrences(for: habit, on: saturday, calendar: calendar)

        #expect(result.isEmpty)
    }
}
