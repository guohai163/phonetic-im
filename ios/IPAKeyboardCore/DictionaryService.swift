import Foundation

enum DictionaryVariant: String, CaseIterable {
    case enUK = "en_UK"
    case enUS = "en_US"

    var titleSuffix: String { rawValue }
}

struct DictEntry {
    let word: String
    let ipa: String
    let source: String
}

final class DictionaryService {
    static let shared = DictionaryService()

    private let cacheStore: DictionaryCacheStore
    private let builtinLoader: (DictionaryVariant) -> [String: [String]]
    private var cache: [String: [String]] = [:]
    private var builtin: [String: [String]] = [:]
    private(set) var currentVariant: DictionaryVariant

    init(
        cacheStore: DictionaryCacheStore = DictionaryCacheStore(),
        initialVariant: DictionaryVariant = KeyboardSettings.loadDictionaryVariant(),
        builtinLoader: @escaping (DictionaryVariant) -> [String: [String]] = BuiltinMiniLexicon.load
    ) {
        self.cacheStore = cacheStore
        self.currentVariant = initialVariant
        self.builtinLoader = builtinLoader
        cache = cacheStore.load()
        builtin = builtinLoader(initialVariant)
    }

    func builtinCount() -> Int {
        builtin.count
    }

    func switchVariant(_ variant: DictionaryVariant) {
        guard currentVariant != variant else { return }
        currentVariant = variant
        builtin = builtinLoader(variant)
        KeyboardSettings.saveDictionaryVariant(variant)
    }

    func lookup(word: String) async -> [DictEntry] {
        let key = normalize(word)
        guard !key.isEmpty else { return [] }

        if let local = builtin[key], !local.isEmpty {
            return local.map { DictEntry(word: key, ipa: $0, source: "local") }
        }

        if let cached = cache[key], !cached.isEmpty {
            return cached.map { DictEntry(word: key, ipa: $0, source: "cache") }
        }

        return []
    }

    private func normalize(_ word: String) -> String {
        word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
