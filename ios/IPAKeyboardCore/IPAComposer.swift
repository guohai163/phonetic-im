import Foundation

final class IPAComposer {
    private let transliterator: IPATransliterator

    private(set) var mode: InputMode
    private(set) var composeBuffer: String = ""
    private(set) var convertedPreview: String = ""

    init(transliterator: IPATransliterator = .shared, mode: InputMode = KeyboardSettings.loadInputMode()) {
        self.transliterator = transliterator
        self.mode = mode
    }

    func setMode(_ mode: InputMode) {
        self.mode = mode
        KeyboardSettings.saveInputMode(mode)
        clearBuffer()
    }

    func handleLetter(_ letter: String) -> ComposerUpdate {
        composeBuffer += letter.lowercased()

        switch mode {
        case .candidate:
            convertedPreview = transliterator.convertAll(code: composeBuffer)
            return ComposerUpdate(
                textToInsert: nil,
                backspaceCount: 0,
                candidates: transliterator.previewCandidates(for: composeBuffer),
                composeBuffer: composeBuffer,
                convertedPreview: convertedPreview
            )
        case .dictionary:
            convertedPreview = composeBuffer
            return ComposerUpdate(
                textToInsert: nil,
                backspaceCount: 0,
                candidates: [],
                composeBuffer: composeBuffer,
                convertedPreview: convertedPreview
            )
        }
    }

    func commitCurrentBuffer() -> ComposerUpdate {
        guard !composeBuffer.isEmpty else {
            return ComposerUpdate.empty(mode: mode)
        }

        let committed: String
        switch mode {
        case .candidate:
            committed = transliterator.convertAll(code: composeBuffer)
        case .dictionary:
            committed = composeBuffer
        }

        clearBuffer()
        return ComposerUpdate(
            textToInsert: committed,
            backspaceCount: 0,
            candidates: [],
            composeBuffer: composeBuffer,
            convertedPreview: convertedPreview
        )
    }

    func applyDelimiter(_ delimiter: String) -> ComposerUpdate {
        let commit = commitCurrentBuffer()
        let text = (commit.textToInsert ?? "") + delimiter
        return ComposerUpdate(
            textToInsert: text,
            backspaceCount: 0,
            candidates: [],
            composeBuffer: composeBuffer,
            convertedPreview: convertedPreview
        )
    }

    func applyBackspace() -> ComposerUpdate {
        if !composeBuffer.isEmpty {
            composeBuffer.removeLast()
            if mode == .candidate {
                convertedPreview = transliterator.convertAll(code: composeBuffer)
                let candidates = composeBuffer.isEmpty ? [] : transliterator.previewCandidates(for: composeBuffer)
                return ComposerUpdate(
                    textToInsert: nil,
                    backspaceCount: 0,
                    candidates: candidates,
                    composeBuffer: composeBuffer,
                    convertedPreview: convertedPreview
                )
            } else {
                convertedPreview = composeBuffer
                return ComposerUpdate(
                    textToInsert: nil,
                    backspaceCount: 0,
                    candidates: [],
                    composeBuffer: composeBuffer,
                    convertedPreview: convertedPreview
                )
            }
        }

        return ComposerUpdate(
            textToInsert: nil,
            backspaceCount: 1,
            candidates: [],
            composeBuffer: composeBuffer,
            convertedPreview: convertedPreview
        )
    }

    func tapCandidate(_ candidate: String) -> ComposerUpdate {
        clearBuffer()
        return ComposerUpdate(
            textToInsert: candidate,
            backspaceCount: 0,
            candidates: [],
            composeBuffer: composeBuffer,
            convertedPreview: convertedPreview
        )
    }

    func clearBuffer() {
        composeBuffer = ""
        convertedPreview = ""
    }
}

struct ComposerUpdate {
    let textToInsert: String?
    let backspaceCount: Int
    let candidates: [String]
    let composeBuffer: String
    let convertedPreview: String

    static func empty(mode: InputMode) -> ComposerUpdate {
        ComposerUpdate(textToInsert: nil, backspaceCount: 0, candidates: [], composeBuffer: "", convertedPreview: "")
    }
}
