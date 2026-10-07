import Foundation
// Inputs are frozen at bb2ee61: do not union the current production dictionary.
guard CommandLine.arguments.count == 2 else { fatalError("usage: audit frozen-fixtures.tsv") }
let text = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
print("kind\tlang\tword\tinput\tfresh\truContext\tenContext")
for line in text.split(separator: "\n").dropFirst() {
    let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    precondition(fields.count == 4)
    var results: [String] = []
    for seed in ["", "привет", "hello"] {
        let detector = Detector()
        if !seed.isEmpty { _ = detector.verdict(for: seed) }
        results.append(String(describing: detector.verdict(for: fields[3])))
    }
    print((fields + results).joined(separator: "\t"))
}
