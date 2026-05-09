import Foundation

enum BuiltinMiniLexicon {
    static func load() -> [String: [String]] {
        let bundle = Bundle.main
        let candidateURLs: [URL?] = [
            bundle.url(forResource: "en_UK", withExtension: "txt"),
            bundle.url(forResource: "en_UK", withExtension: "txt", subdirectory: "data")
        ]

        guard let url = candidateURLs.compactMap({ $0 }).first,
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }

        var dict: [String: [String]] = [:]
        for line in content.split(whereSeparator: \Character.isNewline) {
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }

            let word = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            var ipa = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            ipa = ipa.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            guard !word.isEmpty, !ipa.isEmpty else { continue }
            dict[word, default: []].append(ipa)
        }

        for (k, values) in dict {
            var seen = Set<String>()
            dict[k] = values.filter { seen.insert($0).inserted }
        }

        return dict
    }
}
