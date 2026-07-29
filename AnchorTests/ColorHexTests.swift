import Testing
import SwiftUI
@testable import Anchor

@Suite("Color+Hex")
struct ColorHexTests {
    @Test("hex round-trips through Color(hex:) and toHexInt()", arguments: [
        UInt(0x6E6BFF), UInt(0xFF6B6B), UInt(0x000000), UInt(0xFFFFFF), UInt(0x34E5A8)
    ])
    func hexRoundTrips(hex: UInt) {
        let color = Color(hex: hex)
        #expect(color.toHexInt() == hex)
    }
}
