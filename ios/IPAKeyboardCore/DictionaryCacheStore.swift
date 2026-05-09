import Foundation

final class DictionaryCacheStore {
    private let fileURL: URL

    init(filename: String = "ipa_dictionary_cache.json") {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        fileURL = base.appendingPathComponent(filename)
    }

    func load() -> [String: [String]] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }

    func save(_ dict: [String: [String]]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
