import Foundation
import GigaSTT
import Darwin

struct Response: Encodable {
    let text: String?
    let error: String?
}
func finish(text: String? = nil, error: String? = nil, status: Int32 = 0) -> Never {
    let data = try! JSONEncoder().encode(Response(text: text, error: error))
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([10]))
    exit(status)
}

let args = CommandLine.arguments
// Basename only: upstream rejects absolute/parent paths and CWD escapes.
guard args.count == 3, args[1].hasPrefix("/"), !args[2].isEmpty,
      args[2] != ".", args[2] != "..", !args[2].contains("/") else {
    finish(error: "invalid_arguments", status: 2)
}
guard FileManager.default.fileExists(atPath: args[2]) else {
    finish(error: "invalid_audio", status: 2)
}
do {
    let engine: GigaSTT.Engine
    do { engine = try GigaSTT.Engine(modelDir: args[1], poolSize: 1) }
    catch { finish(error: "model_load_failed", status: 3) }
    // Upstream file pipeline segments long audio; do not truncate or use the
    // streaming API (which has different buffering / finalization semantics).
    let text = try engine.transcribeFile(path: args[2])
        .trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { finish(error: "no_speech", status: 4) }
    finish(text: text)
} catch {
    // Never forward the engine's error payload or audio/transcript to logs.
    finish(error: "inference_failed", status: 5)
}
