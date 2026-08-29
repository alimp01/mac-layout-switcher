/// Конвертация строк между раскладками ЙЦУКЕН и QWERTY
/// (по физическим клавишам ANSI-клавиатуры).
public enum KeyMap {
    /// QWERTY → ЙЦУКЕН, строчные буквы (ряд за рядом ANSI-клавиатуры).
    private static let enToRuLower: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н",
        "u": "г", "i": "ш", "o": "щ", "p": "з",
        "a": "ф", "s": "ы", "d": "в", "f": "а", "g": "п", "h": "р",
        "j": "о", "k": "л", "l": "д",
        "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и", "n": "т",
        "m": "ь",
    ]

    /// Пунктуационные клавиши ANSI, оба «регистра» (без Shift / с Shift):
    /// `;:'"[]{},.<>` и `` ` ``/`~` → ё/Ё. Заглавные из них не выводятся
    /// uppercased(), поэтому перечислены явно.
    private static let enToRuPunct: [Character: Character] = [
        ";": "ж", ":": "Ж",
        "'": "э", "\"": "Э",
        "[": "х", "{": "Х",
        "]": "ъ", "}": "Ъ",
        ",": "б", "<": "Б",
        ".": "ю", ">": "Ю",
        "`": "ё", "~": "Ё",
    ]

    /// Полная прямая карта: строчные + производные заглавные пары.
    private static let enToRu: [Character: Character] = {
        var map = enToRuLower
        for (en, ru) in enToRuLower {
            let enUp = Character(String(en).uppercased())
            let ruUp = Character(String(ru).uppercased())
            if enUp != en { map[enUp] = ruUp }
        }
        map.merge(enToRuPunct) { current, _ in current }
        return map
    }()

    /// Обратная карта, вычисляется из прямой — таблица одна.
    private static let ruToEn: [Character: Character] =
        Dictionary(uniqueKeysWithValues: enToRu.map { ($1, $0) })

    /// Переводит строку в указанную раскладку.
    /// Символы вне карты остаются без изменений.
    public static func convert(_ s: String, to lang: Lang) -> String {
        let map = (lang == .ru) ? enToRu : ruToEn
        return String(s.map { map[$0] ?? $0 })
    }
}
