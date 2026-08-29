// Системный слой macOS. Весь файл — под #if os(macOS): на Linux target
// собирается в пустой executable, чтобы `swift build`/`swift test` были зелёными.
#if os(macOS)
import Foundation

/// Типизированные настройки приложения (config.json).
/// snippets.json и exclusions.json — отдельные файлы, ими владеют
/// `SnippetStore`/`Detector`; `Config` лишь отдаёт их URL.
public struct AppConfig: Codable, Equatable {
    /// Глобальный тумблер автоисправления по детектору.
    public var autoSwitch: Bool
    /// Озвучка клавиш (реализация звука — таск UI/звуков).
    public var sounds: Bool
    /// Приложения-исключения (bundle id) — в них автоматика молчит.
    public var excludedApps: [String]

    /// Дефолтные исключения — терминалы/IDE, как у Caramba (spec, A01).
    public static let defaultExcludedApps = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.microsoft.VSCode",
    ]

    public static let `default` = AppConfig(
        autoSwitch: true,
        sounds: false,
        excludedApps: defaultExcludedApps
    )
}

/// Хранилище настроек в `~/Library/Application Support/MacLayoutSwitcher/`.
/// Дефолты при отсутствии файла; битый config.json → бэкап `.broken` рядом
/// и дефолты. Пути/дефолты/миграции спрятаны за этим типом.
public final class Config {

    /// Текущие настройки (после `load()`; до него — дефолты).
    public private(set) var config: AppConfig = .default

    /// Каталог с файлами настроек.
    public let directory: URL

    private var configURL: URL { directory.appendingPathComponent("config.json") }
    /// URL файла шаблонов автозамены (грузит `SnippetStore`).
    public var snippetsURL: URL { directory.appendingPathComponent("snippets.json") }
    /// URL файла слов-исключений (грузит/пишет `Detector`).
    public var exclusionsURL: URL { directory.appendingPathComponent("exclusions.json") }

    /// `directory == nil` → штатный Application Support; иначе (тесты/перенос)
    /// заданный каталог.
    public init(directory: URL? = nil) {
        self.directory = directory ?? Self.defaultDirectory()
    }

    private static func defaultDirectory() -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("MacLayoutSwitcher", isDirectory: true)
    }

    /// Читает config.json. Нет файла → дефолты и запись. Битый → бэкап
    /// `config.json.broken` и дефолты.
    public func load() {
        ensureDirectory()
        guard let data = try? Data(contentsOf: configURL) else {
            config = .default
            save()
            return
        }
        guard let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            backupBroken(configURL)
            config = .default
            save()
            return
        }
        config = decoded
    }

    /// Пишет config.json (атомарно, стабильный порядок ключей для диффов).
    public func save() {
        ensureDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    /// Меняет настройки и сразу сохраняет.
    public func update(_ mutate: (inout AppConfig) -> Void) {
        mutate(&config)
        save()
    }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)
    }

    private func backupBroken(_ url: URL) {
        let broken = url.appendingPathExtension("broken")
        try? FileManager.default.removeItem(at: broken)
        try? FileManager.default.moveItem(at: url, to: broken)
    }
}
#endif
