import UIKit

/// 键盘扩展控制器：连接输入引擎、词典查询与键盘视图事件。
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

    /// 将自定义键盘视图铺满输入视图容器。
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

    /// 应用输入引擎返回的更新（删字、插入、刷新候选）。
    private func apply(update: ComposerUpdate) {
        if update.backspaceCount > 0 {
            (0..<update.backspaceCount).forEach { _ in textDocumentProxy.deleteBackward() }
        }

        if let text = update.textToInsert, !text.isEmpty {
            textDocumentProxy.insertText(text)
        }

        refreshStatusAndCandidates(update.candidates)
    }

    /// 将当前引擎状态同步到界面。
    private func refreshStatusAndCandidates(_ candidates: [String]) {
        keyboardView.updateCandidates(candidates)
        keyboardView.updateStatus(
            mode: composer.mode,
            composeBuffer: composer.composeBuffer,
            preview: composer.convertedPreview
        )
    }

    /// 词典模式下按输入码触发本地/离线词典查询。
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

    /// 根据宿主输入框的 ReturnKeyType 更新底部动作键语义。
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

    /// 执行底部动作键：优先提交词典首候选，否则提交当前缓冲并换行。
    private func performContextAction() {
        if composer.mode == .dictionary {
            let ipa = firstDictionaryCandidateIPA()
            apply(update: composer.tapCandidate(ipa))
            textDocumentProxy.insertText("\n")
            return
        }
        let commit = composer.commitCurrentBuffer()
        apply(update: commit)
        textDocumentProxy.insertText("\n")
    }

    /// In dictionary mode, extract the IPA from the first candidate (format: "ipa [source]").
    /// Falls back to the raw compose buffer if no candidate is available.
    private func firstDictionaryCandidateIPA() -> String {
        if let first = keyboardView.currentCandidates.first {
            let ipa = first.components(separatedBy: " [").first ?? first
            if !ipa.hasPrefix("(") { return ipa }   // skip error placeholders like "(offline/miss)"
        }
        return composer.composeBuffer
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
            let ipa = firstDictionaryCandidateIPA()
            apply(update: composer.tapCandidate(ipa))
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

    func keyboardViewDidTapModifier(_ value: String) {
        textDocumentProxy.insertText(value)
    }

    func keyboardViewDidSelectAlternative(_ value: String) {
        textDocumentProxy.insertText(value)
    }
}
