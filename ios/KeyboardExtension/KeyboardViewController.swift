import UIKit

final class KeyboardViewController: UIInputViewController {
    private let composer = IPAComposer()
    private let keyboardView = KeyboardView()
    private let dictionaryService = DictionaryService.shared
    private var bottomAction: KeyboardView.BottomAction = .none

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
        refreshStatusAndCandidates([])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        composer.setMode(KeyboardSettings.loadInputMode())
        refreshStatusAndCandidates([])
        updateContextAction()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateContextAction()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        updateContextAction()
    }

    private func setupKeyboardView() {
        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)

        NSLayoutConstraint.activate([
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func apply(update: ComposerUpdate) {
        if update.backspaceCount > 0 {
            (0..<update.backspaceCount).forEach { _ in textDocumentProxy.deleteBackward() }
        }

        if let text = update.textToInsert, !text.isEmpty {
            textDocumentProxy.insertText(text)
        }

        refreshStatusAndCandidates(update.candidates)
    }

    private func refreshStatusAndCandidates(_ candidates: [String]) {
        keyboardView.updateCandidates(candidates)
        keyboardView.updateStatus(
            mode: composer.mode,
            composeBuffer: composer.composeBuffer,
            preview: composer.convertedPreview
        )
    }

    private func handleDictionaryLookupIfNeeded() {
        guard composer.mode == .dictionary else { return }
        let q = composer.composeBuffer
        guard q.count >= 2 else {
            refreshStatusAndCandidates([])
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let entries = await dictionaryService.lookup(word: q)
            let candidates: [String]
            if entries.isEmpty {
                candidates = [self.dictionaryService.builtinCount() == 0 ? "(dict_missing)" : "(offline/miss)"]
            } else {
                candidates = entries.map { "\($0.ipa) [\($0.source)]" }
            }
            await MainActor.run {
                self.keyboardView.updateCandidates(candidates)
                self.keyboardView.updateStatus(
                    mode: self.composer.mode,
                    composeBuffer: self.composer.composeBuffer,
                    preview: self.composer.convertedPreview
                )
            }
        }
    }

    private func updateContextAction() {
        let action: KeyboardView.BottomAction
        switch textDocumentProxy.returnKeyType {
        case .send:
            action = .send
        case .search:
            action = .search
        case .go:
            action = .go
        case .next:
            action = .next
        case .done:
            action = .done
        case .default:
            action = .return
        default:
            action = .return
        }
        bottomAction = action
        keyboardView.updateBottomAction(action)
    }

    private func performContextAction() {
        let commit = composer.commitCurrentBuffer()
        apply(update: commit)
        textDocumentProxy.insertText("\n")
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardViewDidTapLetter(_ letter: String) {
        apply(update: composer.handleLetter(letter))
        handleDictionaryLookupIfNeeded()
    }

    func keyboardViewDidTapCandidate(_ candidate: String) {
        if composer.mode == .dictionary {
            let value = candidate.components(separatedBy: " [").first ?? candidate
            apply(update: composer.tapCandidate(value))
            return
        }
        apply(update: composer.tapCandidate(candidate))
    }

    func keyboardViewDidTapBackspace() {
        apply(update: composer.applyBackspace())
    }

    func keyboardViewDidTapSpace() {
        if composer.mode == .dictionary {
            let commit = composer.commitCurrentBuffer()
            apply(update: commit)
            textDocumentProxy.insertText(" ")
            return
        }
        apply(update: composer.applyDelimiter(" "))
    }

    func keyboardViewDidTapReturn() {
        apply(update: composer.applyDelimiter("\n"))
    }

    func keyboardViewDidTapPunctuation(_ punctuation: String) {
        apply(update: composer.applyDelimiter(punctuation))
    }

    func keyboardViewDidTapNextKeyboard() {
        advanceToNextInputMode()
    }

    func keyboardViewDidSwitchFeature() {
        let next: InputMode = composer.mode == .candidate ? .dictionary : .candidate
        composer.setMode(next)
        refreshStatusAndCandidates([])
    }

    func keyboardViewDidToggleSymbolPanel() {
        refreshStatusAndCandidates([])
        updateContextAction()
    }

    func keyboardViewDidTapContextAction() {
        performContextAction()
    }

    func keyboardViewDidTapQuickIPA(_ ipa: String) {
        textDocumentProxy.insertText(ipa)
    }

    func keyboardViewDidSelectAlternative(_ value: String) {
        textDocumentProxy.insertText(value)
    }
}
