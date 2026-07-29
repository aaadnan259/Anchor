import Testing
@testable import Anchor

@Suite("String+Icon")
struct StringIconTests {
    @Test("an SF Symbol name is SF Symbol compatible")
    func sfSymbolNameIsCompatible() {
        #expect("drop.fill".isSFSymbolCompatible)
        #expect("moon.stars.fill".isSFSymbolCompatible)
    }

    @Test("a simple emoji is not SF Symbol compatible")
    func simpleEmojiIsNotCompatible() {
        #expect(!"💧".isSFSymbolCompatible)
    }

    @Test("a compound (ZWJ/keycap) emoji is not SF Symbol compatible")
    func compoundEmojiIsNotCompatible() {
        #expect(!"👨‍👩‍👧‍👦".isSFSymbolCompatible)
        #expect(!"1️⃣".isSFSymbolCompatible)
    }
}
