import Foundation

struct KeyModel: Hashable {
    enum Role {
        case character
        case special
        case action
    }

    let id: String
    let primaryLabel: String
    let secondaryLabel: String
    let output: String
    let role: Role
    let alternatives: [String]
    let accessibilityLabel: String
}

struct KeyboardViewModel {
    var composingCode: String
    var convertedIPA: String
    var candidateList: [String]

    static let empty = KeyboardViewModel(composingCode: "", convertedIPA: "", candidateList: [])
}

enum KeyboardLayout {
    static let letterRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    static let symbolRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'", "#"]
    ]

    static let quickIPA: [String] = ["ə", "æ", "ɪ", "ʊ", "θ", "ð", "ʃ", "ŋ"]

    static let secondaryIPA: [String: String] = [
        "q": "ə", "a": "æ", "i": "ɪ", "u": "ʌ", "o": "ɒ", "x": "ʃ", "c": "tʃ", "j": "dʒ", "y": "j", "n": "ŋ"
    ]

    static let alternatives: [String: [String]] = [
        "a": ["æ", "ɑː", "eə"],
        "i": ["ɪ", "iː", "ɪə", "aɪ"],
        "o": ["ɒ", "ɔː", "ɔɪ", "əʊ"],
        "u": ["ʌ", "ʊ", "uː", "ʊə"],
        "t": ["t", "θ", "ð", "tʃ"],
        "s": ["s", "ʃ", "ʒ"],
        "n": ["n", "ŋ"],
        "j": ["dʒ", "j"]
    ]
}
