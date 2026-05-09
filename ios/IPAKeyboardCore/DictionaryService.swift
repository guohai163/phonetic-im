import Foundation

struct DictEntry {
    let word: String
    let ipa: String
    let source: String
}

final class DictionaryService {
    static let shared = DictionaryService()

    private let cacheStore = DictionaryCacheStore()
    private var cache: [String: [String]] = [:]
    private var builtin: [String: [String]] = [:]

    private init() {
        cache = cacheStore.load()
        builtin = BuiltinMiniLexicon.load()
    }

    func builtinCount() -> Int {
        builtin.count
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
