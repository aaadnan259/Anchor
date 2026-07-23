import SwiftUI

extension Font {
    static let anchorLargeTitle = Font.system(.largeTitle, weight: .bold)
    static let anchorTitle = Font.system(.title2, weight: .semibold)
    static let anchorHeadline = Font.system(.headline, weight: .semibold)
    static let anchorBody = Font.system(.body)
    static let anchorSubheadline = Font.system(.subheadline)
    static let anchorCaption = Font.system(.caption, weight: .medium)
    static let anchorFootnote = Font.system(.footnote)
    static let anchorNumeric = Font.system(.headline, weight: .bold).monospacedDigit()
}
