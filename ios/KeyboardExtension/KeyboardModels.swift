import Foundation

/// 单个按键在视图层的展示与交互模型。
struct KeyModel: Hashable {
    /// 按键语义角色，用于后续按样式或行为区分。
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

/// 键盘当前状态的展示模型（输入码、转换结果、候选列表）。
struct KeyboardViewModel {
    var composingCode: String
    var convertedIPA: String
    var candidateList: [String]

    /// 默认空状态，供初始化或重置 UI 使用。
    static let empty = KeyboardViewModel(composingCode: "", convertedIPA: "", candidateList: [])
}

/// 键盘布局与静态映射数据（按键行、次标、长按候选）。
enum KeyboardLayout {
    /// 字母面板三行布局。
    static let letterRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    /// 符号面板三行布局。
    static let symbolRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'", "#"]
    ]

    /// 字母按键对应的 IPA 次标（显示在按键下方）。

    static let secondaryIPA: [String: String] = [
        "q": "ə", "w": "w", "e": "e", "r": "r", "t": "t", "y": "j", "u": "ʌ", "i": "ɪ", "o": "ɒ", "p": "p",
        "a": "æ", "s": "s", "d": "d", "f": "f", "g": "g", "h": "h", "j": "dʒ", "k": "k", "l": "l",
        "z": "z", "x": "ʃ", "c": "tʃ", "v": "v", "b": "b", "n": "ŋ", "m": "m"
    ]

    /// 长按按键时可选的替代音标。
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
