import AppKit
import CoreGraphics

let harnessConfigDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
var harnessAllowTap = true
var harnessActiveTaps = Set<CFHashCode>()
var harnessMenus: [NSMenu] = []
var harnessAlerts: [String] = []
private let focusLock = NSLock()
private var focusReads = 0
func harnessFocusTrust() -> Bool {
    focusLock.lock(); focusReads += 1; focusLock.unlock()
    return false // Stop at the permission boundary: never query a foreign AX tree.
}
func harnessFocusReads() -> Int {
    focusLock.lock(); defer { focusLock.unlock() }; return focusReads
}
func harnessTapCreate(tap: CGEventTapLocation, place: CGEventTapPlacement,
                      options: CGEventTapOptions, eventsOfInterest: CGEventMask,
                      callback: CGEventTapCallBack, userInfo: UnsafeMutableRawPointer?) -> CFMachPort? {
    guard harnessAllowTap else { return nil }
    // A private Mach port exercises production EventTap ownership/run-loop code.
    // It is not a CGEventTap and never observes or posts global input.
    return CFMachPortCreate(kCFAllocatorDefault, { _, _, _, _ in }, nil, nil)
}
func harnessTapEnable(tap: CFMachPort, enable: Bool) {
    if enable { harnessActiveTaps.insert(CFHash(tap)) }
    else { harnessActiveTaps.remove(CFHash(tap)) }
}
func harnessAlert(_ alert: NSAlert) -> NSApplication.ModalResponse {
    harnessAlerts.append(alert.messageText + " " + alert.informativeText)
    return .alertThirdButtonReturn
}
