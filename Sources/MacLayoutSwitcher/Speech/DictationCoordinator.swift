#if os(macOS)
import AppKit
import AVFoundation
import SwitcherCore

/// Main-queue coordinator. The tap only schedules hold/release calls here;
/// model I/O, microphone setup, AX requests and ASR run on worker queues.
final class DictationCoordinator {
    private var session = DictationSession()
    private let store = SpeechModelStore()
    private let recognizer = SpeechRecognitionProcess()
    private let recorder = DictationRecorder()
    private let panel = DictationPanel()
    private let focusQueue = DispatchQueue(label: "MacLayoutSwitcher.DictationFocus", qos: .userInitiated)
    private var ready = false
    private var target: DictationTarget?
    private var insertionPermit: DictationInsertionPermit?
    private var timer: Timer?
    private var recordingSince: Date?
    private var resultText: String?
    var shortcutName: () -> String = { Hotkey.defaultDictation.displayName }
    var onStatus: ((String) -> Void)?
    var onInsert: ((String, DictationTarget, DictationInsertionPermit, @escaping (String) -> Void) -> Void)?
    var isActive: Bool { session.phase != .idle }
    var isInserting: Bool { session.phase == .inserting }
    var paused = false

    init() {
        recorder.onUnexpectedStop = { [weak self] token, success in
            guard let self, token == self.session.id, self.session.phase == .recording else { return }
            if success { self.release() }
            else { self.fail(token, "Микрофон перестал записывать. Проверьте устройство и повторите.") }
        }
    }

    func showSetup() {
        if isActive { return } // Existing progress HUD is already visible.
        if let resultText { showResult(resultText); return }
        guard !paused else { panel.show("Снимите паузу переключателя, чтобы использовать диктовку."); return }
        guard let token = session.begin(ready: false) else { return }
        prepare(token)
    }

    func hold() {
        guard !paused, !SecureInput.isActive, !isActive else { return }
        guard let token = session.begin(ready: ready && AVCaptureDevice.authorizationStatus(for: .audio) == .authorized) else { return }
        resultText = nil
        if session.phase == .preparing { prepare(token); return }
        let expectedPID = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
        onStatus?("🎙 …")
        panel.show("Включаем микрофон… Отпустите сочетание для завершения, Esc — отмена.",
                   cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
        focusQueue.async { [weak self] in
            let target = DictationTarget.capture(expectedPID: expectedPID)
            DispatchQueue.main.async {
                guard let self, self.session.id == token, self.session.phase == .starting else { return }
                guard !SecureInput.isActive else { self.cancel(); return }
                switch target {
                case .target(let destination): self.target = destination
                case .unavailable: self.target = nil
                case .protectedField:
                    self.fail(token, "Диктовка недоступна в защищённом поле.")
                    return
                }
                self.recorder.start(token: token) { [weak self] result in
                    guard let self, self.session.id == token, self.session.phase == .starting else { return }
                    switch result {
                    case .failure(let error): self.fail(token, error.localizedDescription)
                    case .success:
                        guard self.session.recordingStarted(token) else { return }
                        self.recordingSince = Date()
                        self.updateRecordingTime()
                        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in self?.updateRecordingTime() }
                        self.timer = timer
                        RunLoop.main.add(timer, forMode: .common)
                    }
                }
            }
        }
    }

    func release() {
        let wasStarting = session.phase == .starting
        guard let token = session.release() else {
            if wasStarting { recorder.cancel(); target = nil; onStatus?(""); panel.hide() }
            return
        }
        timer?.invalidate(); timer = nil
        onStatus?("…")
        panel.show("Распознаём локально… Esc — отмена.", cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
        recorder.stop { [weak self] wav in
            guard let self, self.session.id == token, self.session.phase == .transcribing else { return }
            guard let wav else { self.fail(token, "Запись не получена. Удерживайте сочетание и говорите."); return }
            self.recognizer.transcribe(wavURL: wav, modelDirectory: self.store.modelDirectory) { [weak self] result in
                guard let self, self.session.id == token, self.session.phase == .transcribing else { return }
                self.recorder.cancel()
                switch result {
                case .failure(let error):
                    if let speechError = error as? SpeechError {
                        switch speechError {
                        case .missingModel, .damagedModel, .engine: self.ready = false
                        default: break
                        }
                    }
                    self.fail(token, error.localizedDescription)
                case .success(let text): self.recognized(text, token: token)
                }
            }
        }
    }

    func cancel() {
        session.cancel()
        insertionPermit?.cancel(); insertionPermit = nil
        store.cancel(); recognizer.cancel(); recorder.cancel()
        timer?.invalidate(); timer = nil
        target = nil; resultText = nil
        onStatus?("")
        panel.hide()
    }

    /// App termination waits asynchronously for microphone cleanup and helper
    /// termination. The app is already paused, so no new operation can start.
    func shutdown(completion: @escaping () -> Void) {
        paused = true
        cancel()
        let group = DispatchGroup()
        group.enter(); store.shutdown { group.leave() }
        group.enter(); recognizer.shutdown { group.leave() }
        group.enter(); recorder.shutdown { group.leave() }
        group.notify(queue: .main, execute: completion)
    }

    private func prepare(_ token: UInt64) {
        if let reason = SpeechRecognitionProcess.unavailabilityReason { fail(token, reason); return }
        onStatus?("↓")
        panel.show("Проверяем модель GigaAM v3…", cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
        store.checkInstalled { [weak self] result in
            guard let self, self.session.id == token, self.session.phase == .preparing else { return }
            switch result {
            case .success: self.askMicrophone(token)
            case .failure(let error):
                let megabytes = Int((SpeechModelStore.totalDownloadBytes + 999_999) / 1_000_000)
                self.panel.show("\(error.localizedDescription)\nОднократная загрузка: \(megabytes) МБ. Затем речь распознаётся на этом Mac без интернета.",
                    primaryTitle: "Загрузить модель", primaryAction: { [weak self] in self?.download(token) },
                    cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
            }
        }
    }

    private func download(_ token: UInt64) {
        guard token == session.id, session.phase == .preparing else { return }
        let update: (Double) -> Void = { [weak self] fraction in
            guard let self, self.session.id == token, self.session.phase == .preparing else { return }
            self.panel.show("Загрузка и проверка модели: \(Int(fraction * 100))%", progress: fraction,
                            cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
        }
        update(0)
        store.download(progress: update) { [weak self] result in
            guard let self, self.session.id == token, self.session.phase == .preparing else { return }
            switch result {
            case .success: self.askMicrophone(token)
            case .failure(let error): self.fail(token, error.localizedDescription)
            }
        }
    }

    private func askMicrophone(_ token: UInt64) {
        guard token == session.id, session.phase == .preparing else { return }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: setupFinished(token)
        case .notDetermined:
            panel.show("Разрешите микрофон в запросе macOS. Запись начнётся только при следующем удержании сочетания.",
                       cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
                DispatchQueue.main.async {
                    guard let self, token == self.session.id, self.session.phase == .preparing else { return }
                    if allowed { self.setupFinished(token) }
                    else { self.microphoneDenied(token) }
                }
            }
        default: microphoneDenied(token)
        }
    }

    private func microphoneDenied(_ token: UInt64) {
        guard session.failed(token) else { return }
        onStatus?("")
        panel.show("Нет доступа к микрофону. Разрешите Mac Layout Switcher в «Конфиденциальность и безопасность → Микрофон», затем повторите.",
                   primaryTitle: "Настройки микрофона", primaryAction: {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") { NSWorkspace.shared.open(url) }
        })
    }

    private func setupFinished(_ token: UInt64) {
        guard session.prepared(token) else { return }
        ready = true
        onStatus?("")
        panel.show("Готово. Вернитесь в поле, удерживайте \(shortcutName()) и говорите. Отпустите — текст вставится без Enter. Esc — отмена.")
    }

    private func updateRecordingTime() {
        guard session.phase == .recording, let recordingSince else { return }
        if SecureInput.isActive { cancel(); return }
        let elapsed = Int(Date().timeIntervalSince(recordingSince))
        if elapsed >= 300 { release(); return }
        let time = String(format: "%d:%02d", elapsed / 60, elapsed % 60)
        onStatus?("● \(time)")
        panel.show("Запись \(time) / 5:00\nОтпустите \(shortcutName()) — распознать и вставить. Esc — отмена.",
                   cancelTitle: "Отмена", cancelAction: { [weak self] in self?.cancel() })
    }

    private func recognized(_ raw: String, token: UInt64) {
        // Never synthesize Enter/Tab/control characters from model output.
        // Whitespace becomes ordinary spaces before the shared Unicode path.
        let text = DictationText.insertionText(raw)
        guard session.recognized(token, hasText: !text.isEmpty) else {
            onStatus?(""); panel.show("Речь не обнаружена. Удерживайте сочетание и попробуйте снова."); return
        }
        guard let target, let onInsert, !SecureInput.isActive else {
            session.cancel(); self.target = nil; showResult(text); return
        }
        let permit = DictationInsertionPermit()
        insertionPermit = permit
        onInsert(text, target, permit) { [weak self] remaining in
            guard let self, self.session.id == token, self.session.phase == .inserting else { return }
            self.session.cancel(); self.target = nil; self.insertionPermit = nil
            self.onStatus?("")
            if remaining.isEmpty { self.panel.hide() }
            else { self.showResult(remaining) }
        }
    }

    private func showResult(_ text: String) {
        resultText = text
        onStatus?("▤")
        panel.show("Автовставка недоступна или поле изменилось. Ниже текст, который не был вставлен. Скопируйте его вручную.",
                   primaryTitle: "Копировать", primaryAction: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }, cancelTitle: "Готово", cancelAction: { [weak self] in
            self?.resultText = nil; self?.onStatus?(""); self?.panel.hide()
        }, text: text)
    }

    private func fail(_ token: UInt64, _ message: String) {
        guard session.failed(token) else { return }
        recorder.cancel(); recognizer.cancel()
        insertionPermit?.cancel(); insertionPermit = nil
        timer?.invalidate(); timer = nil; target = nil
        onStatus?("")
        panel.show(message, primaryTitle: "Повторить настройку", primaryAction: { [weak self] in self?.showSetup() })
    }
}
#endif
