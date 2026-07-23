import Foundation

struct ExportedCompletion: Codable {
    let occurrence: String
    let day: String
    let completedAt: String
}

struct ExportedHabit: Codable {
    let name: String
    let icon: String
    let frequency: String
    let archived: Bool
    let completions: [ExportedCompletion]
}

struct ExportService {
    func csv(habits: [Habit]) -> String {
        var lines = ["Habit,Occurrence,Day,Completed At"]
        for habit in habits {
            for row in sortedCompletions(for: habit) {
                lines.append([
                    csvField(habit.name),
                    csvField(row.occurrence.title),
                    csvField(dayFormatter.string(from: row.completion.day)),
                    csvField(dateTimeFormatter.string(from: row.completion.completedAt))
                ].joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n")
    }

    func json(habits: [Habit]) -> Data {
        let exported = habits.map { habit in
            ExportedHabit(
                name: habit.name,
                icon: habit.icon,
                frequency: habit.frequency.displayName,
                archived: habit.archived,
                completions: sortedCompletions(for: habit).map {
                    ExportedCompletion(
                        occurrence: $0.occurrence.title,
                        day: dayFormatter.string(from: $0.completion.day),
                        completedAt: dateTimeFormatter.string(from: $0.completion.completedAt)
                    )
                }
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(exported)) ?? Data()
    }

    func csvFileURL(habits: [Habit]) -> URL? {
        writeTempFile(csv(habits: habits), filename: "Anchor Export.csv")
    }

    func jsonFileURL(habits: [Habit]) -> URL? {
        writeTempFile(json(habits: habits), filename: "Anchor Export.json")
    }

    private func sortedCompletions(for habit: Habit) -> [(occurrence: Occurrence, completion: Completion)] {
        habit.occurrences
            .flatMap { occurrence in occurrence.completions.map { (occurrence: occurrence, completion: $0) } }
            .sorted { $0.completion.day < $1.completion.day }
    }

    private func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private var dayFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }

    private var dateTimeFormatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }

    private func writeTempFile(_ content: String, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        return (try? content.write(to: url, atomically: true, encoding: .utf8)) != nil ? url : nil
    }

    private func writeTempFile(_ content: Data, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        return (try? content.write(to: url, options: .atomic)) != nil ? url : nil
    }
}
