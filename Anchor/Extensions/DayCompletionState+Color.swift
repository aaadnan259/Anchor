import SwiftUI

extension DayCompletionState {
    /// Shared color mapping used by both the dot-matrix heatmap and the calendar history view.
    func color(tint: Color) -> Color {
        switch self {
        case .completed: tint
        case .shielded: Color.blue.opacity(0.6)
        case .partial: tint.opacity(0.45)
        case .missed: tint.opacity(0.15)
        case .notDue: Color.primary.opacity(0.08)
        }
    }
}
