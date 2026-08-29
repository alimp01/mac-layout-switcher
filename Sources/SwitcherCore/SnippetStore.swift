import Foundation

/// Хранилище шаблонов автозамены: сокращение → развёрнутый текст.
/// Формат хранения — деталь реализации (JSON-объект строка→строка).
public final class SnippetStore {
    private var snippets: [String: String] = [:]

    public init() {}

    /// Загружает шаблоны из файла. Отсутствующий или битый файл
    /// означает пустой набор шаблонов, а не ошибку.
    public func load(from url: URL) {
        guard
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            snippets = [:]
            return
        }
        snippets = decoded
    }

    /// Возвращает развёрнутый текст для сокращения, если шаблон есть.
    public func expansion(for abbrev: String) -> String? {
        return snippets[abbrev]
    }
}
