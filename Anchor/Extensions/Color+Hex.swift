import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }

    /// Packs this color's RGB components into `0xRRGGBB`, ignoring alpha. Uses `getRed(_:green:blue:alpha:)`
    /// rather than raw `cgColor.components` so monochrome (gray/white/black) colors convert correctly too.
    func toHexInt() -> UInt? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (UInt((red * 255).rounded()) << 16) | (UInt((green * 255).rounded()) << 8) | UInt((blue * 255).rounded())
    }
}
