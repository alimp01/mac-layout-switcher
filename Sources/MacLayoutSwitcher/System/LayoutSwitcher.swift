// Системный слой macOS. Весь файл — под #if os(macOS).
#if os(macOS)
import Foundation
import Carbon.HIToolbox
import SwitcherCore

/// Системная раскладка через Text Input Sources (HIToolbox):
/// `TISCopyCurrentKeyboardInputSource` — узнать текущую,
/// `TISCreateInputSourceList` + `TISSelectInputSource` — переключить.
///
/// Источник опознаётся по id (`kTISPropertyInputSourceID`, например
/// "com.apple.keylayout.Russian") и локализованному имени: содержит
/// "Russian" → `.ru`; "U.S."/"ABC"/"British" → `.en`; запасной путь —
/// первый язык из `kTISPropertyInputSourceLanguages` ("ru"/"en").
/// Нет подходящего источника → `nil`/`false`, без крэша.
public enum LayoutSwitcher {

    /// Язык текущей раскладки; `nil`, если источник не опознан как RU/EN
    /// (IME, другой язык) или система не отдала источник.
    public static func current() -> Lang? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        return classify(source)
    }

    /// Переключает раскладку на первый включённый пользователем источник
    /// нужного языка. `false` — источник не найден или система отказала.
    /// Если нужная раскладка уже активна — no-op, `true` (лишний
    /// `TISSelectInputSource` — системный бродкаст, сбивает чужие IME).
    @discardableResult
    public static func select(_ lang: Lang) -> Bool {
        if current() == lang { return true }
        guard let source = findSource(for: lang) else { return false }
        return TISSelectInputSource(source) == noErr
    }

    // MARK: - Внутренности TIS

    /// Первый включённый клавиатурный источник нужного языка.
    /// `TISCreateInputSourceList(nil, false)` — только активированные
    /// пользователем источники, не весь каталог системы.
    private static func findSource(for lang: Lang) -> TISInputSource? {
        guard let cfList = TISCreateInputSourceList(nil, false)?.takeRetainedValue(),
              let sources = cfList as? [TISInputSource]
        else { return nil }
        for source in sources {
            guard isSelectableKeyboardSource(source) else { continue }
            if classify(source) == lang { return source }
        }
        return nil
    }

    /// RU/EN по id и имени источника; запасной путь — язык источника.
    private static func classify(_ source: TISInputSource) -> Lang? {
        let id = stringProperty(source, kTISPropertyInputSourceID) ?? ""
        let name = stringProperty(source, kTISPropertyLocalizedName) ?? ""

        if id.contains("Russian") || name.contains("Russian") || name.contains("Русская") {
            return .ru
        }
        let enTokens = ["ABC", "British", "USInternational", "USExtended", "U.S."]
        if id.hasSuffix(".US") || enTokens.contains(where: { id.contains($0) || name.contains($0) }) {
            return .en
        }
        // Запасной путь: у клавиатурных источников первый элемент
        // kTISPropertyInputSourceLanguages — основной язык ("ru"/"en").
        switch primaryLanguage(of: source) {
        case "ru": return .ru
        case "en": return .en
        default: return nil
        }
    }

    /// Клавиатурная раскладка (не палитра/IME-режим) и её можно выбрать.
    private static func isSelectableKeyboardSource(_ source: TISInputSource) -> Bool {
        guard stringProperty(source, kTISPropertyInputSourceCategory)
                == (kTISCategoryKeyboardInputSource as String)
        else { return false }
        guard let rawPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else {
            return false
        }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(rawPtr).takeUnretainedValue())
    }

    private static func primaryLanguage(of source: TISInputSource) -> String? {
        guard let rawPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else {
            return nil
        }
        let languages = Unmanaged<CFArray>.fromOpaque(rawPtr).takeUnretainedValue() as? [String]
        return languages?.first
    }

    private static func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let rawPtr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(rawPtr).takeUnretainedValue() as String
    }
}
#endif
