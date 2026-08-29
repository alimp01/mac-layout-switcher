// Слой UI/звуков macOS. Весь файл — под #if os(macOS): на Linux target
// собирается в пустой executable, чтобы `swift build`/`swift test` были зелёными.
#if os(macOS)
import AppKit

/// Озвучка ввода (история G02, «как в Punto»). Три события — три звука:
/// тихий клик на каждое нажатие, отдельный сигнал на авто-исправление,
/// третий — на откат. Свои ресурсы не тащим: берём системные звуки macOS
/// из `/System/Library/Sounds/*.aiff` через `NSSound(named:)`; имена — ниже
/// константами, при желании пользователь меняет их правкой этого файла или,
/// в следующем заходе, через config.
///
/// Тумблер `enabled` дублирует поле `AppConfig.sounds`: `Engine` дёргает
/// `play*`, а включает/выключает звук меню-бар (persist пишет `Config`).
public final class Sounds {

    /// Глобальный выключатель звуков (пункт меню «Звуки»).
    public var enabled: Bool

    // Имена системных звуков macOS. Клик — самый лёгкий («Tink»); исправление
    // и откат — заметнее и различимы на слух.
    /// Клик на нажатие клавиши.
    public static let keySoundName = "Tink"
    /// Сигнал успешного авто-исправления/конвертации.
    public static let correctionSoundName = "Pop"
    /// Сигнал отката авто-исправления (Option сразу после исправления).
    public static let undoSoundName = "Funk"

    private let keySound: NSSound?
    private let correctionSound: NSSound?
    private let undoSound: NSSound?

    public init(enabled: Bool) {
        self.enabled = enabled
        // Клик заметно тише прочих — иначе набор превращается в стрельбу.
        keySound = Sounds.load(Sounds.keySoundName, volume: 0.25)
        correctionSound = Sounds.load(Sounds.correctionSoundName, volume: 0.6)
        undoSound = Sounds.load(Sounds.undoSoundName, volume: 0.6)
    }

    private static func load(_ name: String, volume: Float) -> NSSound? {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return nil }
        sound.volume = volume
        return sound
    }

    /// Клик на нажатие клавиши.
    public func playKey() { play(keySound) }
    /// Сигнал авто-исправления/конвертации.
    public func playCorrection() { play(correctionSound) }
    /// Сигнал отката.
    public func playUndo() { play(undoSound) }

    private func play(_ sound: NSSound?) {
        guard enabled, let sound = sound else { return }
        // При быстром наборе предыдущий клик может ещё звучать: NSSound.play()
        // на играющем экземпляре вернул бы false — перезапускаем с начала.
        if sound.isPlaying { sound.stop() }
        sound.play()
    }
}
#endif
