/// Накопитель текущего набираемого слова из потока символов.
/// Что считать границей слова, решает Engine — буфер лишь исполняет команды.
public final class WordBuffer {
    /// Текущее накопленное слово.
    public private(set) var word: String = ""

    public init() {}

    /// Добавляет символ к текущему слову.
    public func append(char: Character) {
        word.append(char)
    }

    /// Убирает последний символ; на пустом слове — ничего не делает.
    public func backspace() {
        if !word.isEmpty {
            word.removeLast()
        }
    }

    /// Граница слова: текущее слово сбрасывается.
    public func boundary() {
        word = ""
    }

    /// Полный сброс состояния.
    public func reset() {
        word = ""
    }
}
