import AppKit
import CoreGraphics
import SwitcherCore

// No system layout changes. KeyTranslator itself is compiled unchanged and
// reads the real current RU/EN source; Engine's selected destination is local.
public enum LayoutSwitcher {
    static var language: Lang = .en
    public static func current() -> Lang? { language }
    @discardableResult public static func select(_ language: Lang) -> Bool {
        self.language = language
        return true
    }
}
let harnessPID: pid_t = 12345
var currentFixture: FixtureAX!
var harnessAccessibility: any DictationAccessibility { currentFixture! }
// Typist's real Self.post already applied its marker and delay. Only the final
// global CGEvent post is replaced with delivery to the private AppKit fixture.
func harnessPost(_ event: CGEvent) {
    currentFixture.receive(event, resolvingPhysicalKey: true)
}
