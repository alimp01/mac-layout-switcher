import Foundation

/// Lifecycle of one hold-to-talk session. Identity invalidates every delayed
/// permission, recorder and recognition callback after cancellation or retry.
/// The platform adapter owns side effects; this value is used on the main queue.
public struct DictationSession: Sendable {
    public enum Phase: Equatable, Sendable {
        case idle, preparing, starting, recording, transcribing, inserting
    }
    public private(set) var phase: Phase = .idle
    public private(set) var id: UInt64 = 0
    public init() {}

    public mutating func begin(ready: Bool) -> UInt64? {
        guard phase == .idle else { return nil }
        id &+= 1
        phase = ready ? .starting : .preparing
        return id
    }
    public mutating func prepared(_ token: UInt64) -> Bool {
        guard token == id, phase == .preparing else { return false }
        phase = .idle // Setup never starts recording, even if the chord is held.
        return true
    }
    public mutating func recordingStarted(_ token: UInt64) -> Bool {
        guard token == id, phase == .starting else { return false }
        phase = .recording
        return true
    }
    /// A returned token asks the adapter to stop and transcribe. Releasing
    /// during setup is harmless; releasing during recorder startup cancels it.
    public mutating func release() -> UInt64? {
        if phase == .starting { cancel(); return nil }
        guard phase == .recording else { return nil }
        phase = .transcribing
        return id
    }
    public mutating func recognized(_ token: UInt64, hasText: Bool) -> Bool {
        guard token == id, phase == .transcribing else { return false }
        phase = hasText ? .inserting : .idle
        return hasText
    }
    @discardableResult public mutating func failed(_ token: UInt64) -> Bool {
        guard token == id, phase != .idle else { return false }
        cancel()
        return true
    }
    public mutating func cancel() { id &+= 1; phase = .idle }
}

/// Tracks the physical gesture separately from the asynchronous session. A
/// consumed key keeps its matching key-up suppressed even after Esc/release.
public struct DictationGesture: Sendable {
    public enum Event: Equatable, Sendable {
        case down(UInt16, repeatKey: Bool), up(UInt16), modifiers
    }
    public enum Action: Equatable, Sendable { case pass, consume, begin, end, endPassingEvent }
    private var held: Hotkey?
    private var consumedKey: UInt16?
    private var waitForModifiersUp = false
    public init() {}
    /// Disconnecting the tap loses key-up events. Forget consumed keys and
    /// modifier-release gates before observing a fresh stream of events.
    public mutating func reset() { self = DictationGesture() }

    public mutating func cancelHold() {
        if held?.keyCode == nil, held != nil { waitForModifiersUp = true }
        held = nil
    }
    public mutating func handle(_ event: Event, modifiers: Set<Hotkey.Modifier>, hotkey: Hotkey?) -> Action {
        if case .up(let code) = event, code == consumedKey {
            consumedKey = nil
            if held != nil { held = nil; return .end }
            return .consume
        }
        if let active = held, !active.modifiers.isSubset(of: modifiers) {
            held = nil
            if active.keyCode == nil { waitForModifiersUp = true }
            return .endPassingEvent
        }
        if case .down(let code, _) = event, code == consumedKey { return .consume }
        if waitForModifiersUp {
            if modifiers.isEmpty { waitForModifiersUp = false }
            return .pass
        }
        guard held == nil, let hotkey else { return .pass }
        switch event {
        case .down(let code, let repeated):
            guard !repeated, hotkey.matches(keyCode: code, modifiers: modifiers) else { return .pass }
            consumedKey = code
        case .modifiers:
            guard hotkey.keyCode == nil, !modifiers.isEmpty,
                  hotkey.matches(keyCode: nil, modifiers: modifiers) else { return .pass }
        case .up: return .pass
        }
        held = hotkey
        return .begin
    }
}

extension Hotkey {
    public static let defaultDictation = Hotkey(keyCode: 49, modifiers: [.control, .option])

    /// Modifier-only dictation starts on press, so it must not be a prefix of
    /// another shortcut. Other modifier taps fire on release and may coexist.
    public func dictationValidationError(convert: Hotkey, toggleAuto: Hotkey?) -> String? {
        let supported: Set<Modifier> = [.control, .option, .command, .shift, .function]
        guard !modifiers.isEmpty, modifiers.isSubset(of: supported), keyCode != 53 else {
            return "Для диктовки нужно сочетание с модификатором; Caps Lock и Escape недоступны."
        }
        for other in [convert, toggleAuto].compactMap({ $0 }) {
            if self == other || (keyCode == nil && modifiers.isSubset(of: other.modifiers)) {
                return "Сочетание диктовки конфликтует с другой горячей клавишей."
            }
        }
        return nil
    }
}

/// Model output is inserted as a single paragraph: control keys must never
/// submit a message or navigate to a different field in the destination app.
public enum DictationText {
    public static func insertionText(_ raw: String) -> String {
        let cleaned = raw.unicodeScalars.map { scalar -> String in
            if CharacterSet.whitespacesAndNewlines.contains(scalar) { return " " }
            if CharacterSet.controlCharacters.contains(scalar) { return "" }
            return String(scalar)
        }.joined()
        return cleaned.split(separator: " ").joined(separator: " ")
    }
}
