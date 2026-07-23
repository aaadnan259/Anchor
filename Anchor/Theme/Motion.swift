import SwiftUI

enum Motion {
    /// Default for expand/collapse and most transitions — restrained, precise.
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.85)
    /// Reserved for the one moment that should feel delightful: habit completion.
    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.65)
}
