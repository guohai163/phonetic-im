import Foundation

enum KeyboardSettings {
    private static let inputModeKey = "ipa.input.mode"
    private static let dictVersionKey = "ipa.dict.version"
    private static let dictUpdatedAtKey = "ipa.dict.updated_at"
    private static let dictCachedKey = "ipa.dict.cached"

    private static var defaults: UserDefaults {
        .standard
    }

    static func loadInputMode() -> InputMode {
        guard let raw = defaults.string(forKey: inputModeKey), let mode = InputMode(rawValue: raw) else {
            return .candidate
        }
        return mode
    }

    static func saveInputMode(_ mode: InputMode) {
        defaults.set(mode.rawValue, forKey: inputModeKey)
    }

    static func loadDictionaryMeta() -> DictionaryMeta {
        DictionaryMeta(
            version: defaults.string(forKey: dictVersionKey) ?? "",
            updatedAt: defaults.double(forKey: dictUpdatedAtKey),
            hasCache: defaults.bool(forKey: dictCachedKey)
        )
    }

    static func saveDictionaryMeta(version: String, hasCache: Bool) {
        defaults.set(version, forKey: dictVersionKey)
        defaults.set(Date().timeIntervalSince1970, forKey: dictUpdatedAtKey)
        defaults.set(hasCache, forKey: dictCachedKey)
    }
}

struct DictionaryMeta {
    let version: String
    let updatedAt: TimeInterval
    let hasCache: Bool
}
