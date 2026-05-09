import Foundation

struct IPATransliterator {
    static let shared = IPATransliterator()

    private let mapping: [String: String] = [
        "aa": "ɑː", "aw": "ɔː", "ii": "iː", "oo": "ʊ", "uu": "uː", "er": "ɜː",
        "ei": "eɪ", "ai": "aɪ", "oi": "ɔɪ", "au": "aʊ", "ou": "əʊ", "ia": "ɪə",
        "ea": "eə", "ua": "ʊə", "th": "θ", "dh": "ð", "sh": "ʃ", "zh": "ʒ",
        "ng": "ŋ", "ch": "tʃ", "a": "æ", "b": "b", "c": "tʃ", "d": "d", "e": "e",
        "f": "f", "g": "g", "h": "h", "i": "ɪ", "j": "dʒ", "k": "k", "l": "l",
        "m": "m", "n": "n", "o": "ɒ", "p": "p", "q": "ə", "r": "r", "s": "s",
        "t": "t", "u": "ʌ", "v": "v", "w": "w", "x": "ʃ", "y": "j", "z": "z"
    ]

    private let maxCodeLength = 2

    func convertAll(code: String) -> String {
        let chars = Array(code)
        var index = 0
        var output = ""

        while index < chars.count {
            if let (mapped, consumed) = longestMatch(in: chars, from: index) {
                output += mapped
                index += consumed
            } else {
                output.append(chars[index])
                index += 1
            }
        }
        return output
    }

    func convertIncremental(buffer: String) -> (committed: String, pending: String) {
        let chars = Array(buffer)
        guard !chars.isEmpty else { return ("", "") }

        if chars.count == 1 {
            return ("", buffer)
        }

        var index = 0
        var output = ""

        while index < chars.count {
            let remaining = chars.count - index
            if remaining == 1 {
                return (output, String(chars[index]))
            }

            if let (mapped, consumed) = longestMatch(in: chars, from: index) {
                output += mapped
                index += consumed
            } else {
                output.append(chars[index])
                index += 1
            }
        }

        return (output, "")
    }

    func previewCandidates(for code: String) -> [String] {
        guard !code.isEmpty else { return [] }
        let transformed = convertAll(code: code)
        if transformed == code {
            return [code]
        }
        return [transformed, code]
    }

    private func longestMatch(in chars: [Character], from index: Int) -> (String, Int)? {
        var length = min(maxCodeLength, chars.count - index)

        while length > 0 {
            let token = String(chars[index..<(index + length)]).lowercased()
            if let mapped = mapping[token] {
                return (mapped, length)
            }
            length -= 1
        }

        return nil
    }
}
