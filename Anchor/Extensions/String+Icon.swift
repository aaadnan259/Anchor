import Foundation

extension String {
    /// SF Symbol names in this app are always plain ASCII (e.g. "drop.fill");
    /// an emoji habit icon never is, so this is a reliable way to pick the right renderer.
    var isSFSymbolCompatible: Bool {
        allSatisfy(\.isASCII)
    }
}
