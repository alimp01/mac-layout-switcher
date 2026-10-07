/// Preconditions for deleting a tracked whole word. AX positions use UTF-16,
/// while the replacement executor deletes grapheme clusters with Backspace.
public struct ReplacementSource {
    public let expected: String
    public init(expected: String) { self.expected = expected }

    public func rangeBeforeCaret(location: Int, selectionLength: Int) -> Range<Int>? {
        let length = expected.utf16.count
        guard !expected.isEmpty, selectionLength == 0, location >= length else { return nil }
        return (location - length)..<location
    }

    /// Away from document start, observed must include the preceding code unit.
    /// Only whitespace establishes a word boundary; a matching tail of a larger
    /// word does not license replacing it (click after `bo`, type `b` → `bob`).
    public func matches(_ observed: String?, atDocumentStart: Bool = true) -> Bool {
        guard let observed else { return false }
        if atDocumentStart { return observed == expected }
        guard let first = observed.first, [" ", "\t", "\n", "\r"].contains(first) else { return false }
        return String(observed.dropFirst()) == expected
    }
}
