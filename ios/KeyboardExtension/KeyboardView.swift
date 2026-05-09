import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardViewDidTapLetter(_ letter: String)
    func keyboardViewDidTapCandidate(_ candidate: String)
    func keyboardViewDidTapBackspace()
    func keyboardViewDidTapSpace()
    func keyboardViewDidTapReturn()
    func keyboardViewDidTapNextKeyboard()
    func keyboardViewDidTapPunctuation(_ punctuation: String)
    func keyboardViewDidSwitchFeature()
    func keyboardViewDidToggleSymbolPanel()
    func keyboardViewDidTapContextAction()
    func keyboardViewDidTapQuickIPA(_ ipa: String)
    func keyboardViewDidSelectAlternative(_ value: String)
}

final class KeyboardView: UIView {
    enum Panel { case letters, symbols }
    enum BottomAction { case none, send, `return`, done, go, search, next }

    private enum Lang {
        case zh, ja, ko, en
        static func current() -> Lang {
            let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if code.hasPrefix("zh") { return .zh }
            if code.hasPrefix("ja") { return .ja }
            if code.hasPrefix("ko") { return .ko }
            return .en
        }
        var spaceTitle: String { self == .zh ? "空格" : "space" }
        var candidateTitle: String {
            switch self { case .zh: return "直输"; case .ja: return "直輸"; case .ko: return "직입"; case .en: return "Direct" }
        }
        var dictionaryTitle: String {
            switch self { case .zh: return "词典"; case .ja: return "辞書"; case .ko: return "사전"; case .en: return "Dict" }
        }
        var ipaResultTitle: String {
            switch self { case .zh: return "音标结果"; case .ja: return "IPA 結果"; case .ko: return "IPA 결과"; case .en: return "IPA Result" }
        }
        var codeTitle: String {
            switch self { case .zh: return "输入码"; case .ja: return "入力コード"; case .ko: return "입력 코드"; case .en: return "Input Code" }
        }
        func actionTitle(_ action: BottomAction) -> String {
            switch (self, action) {
            case (_, .none): return "return"
            case (.zh, .send): return "发送"
            case (.ja, .send): return "送信"
            case (.ko, .send): return "전송"
            case (.en, .send): return "Send"
            case (.zh, .return): return "换行"
            case (.ja, .return): return "改行"
            case (.ko, .return): return "줄바꿈"
            case (.en, .return): return "Return"
            case (.zh, .done): return "完成"
            case (.ja, .done): return "完了"
            case (.ko, .done): return "완료"
            case (.en, .done): return "Done"
            case (.zh, .go): return "前往"
            case (.ja, .go): return "移動"
            case (.ko, .go): return "이동"
            case (.en, .go): return "Go"
            case (.zh, .search): return "搜索"
            case (.ja, .search): return "検索"
            case (.ko, .search): return "검색"
            case (.en, .search): return "Search"
            case (.zh, .next): return "下一项"
            case (.ja, .next): return "次へ"
            case (.ko, .next): return "다음"
            case (.en, .next): return "Next"
            }
        }
    }

    private final class KeyboardKeyButton: UIControl {
        let key: KeyModel
        private let primary = UILabel()
        private let secondary = UILabel()
        private let overlay = UIView()
        var onTap: (() -> Void)?
        var onLongPress: ((KeyboardKeyButton) -> Void)?

        init(key: KeyModel, isDark: Bool) {
            self.key = key
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = isDark ? 0.18 : 0.1
            layer.shadowRadius = 0.8
            layer.shadowOffset = CGSize(width: 0, height: 1)
            backgroundColor = key.role == .character
                ? (isDark ? KeyboardDesignTokens.Palette.keyNormalDark : KeyboardDesignTokens.Palette.keyNormalLight)
                : (isDark ? KeyboardDesignTokens.Palette.keySpecialDark : KeyboardDesignTokens.Palette.keySpecialLight)

            primary.font = key.role == .character ? KeyboardDesignTokens.Typography.primary : KeyboardDesignTokens.Typography.function
            primary.text = key.primaryLabel
            primary.textAlignment = .center
            primary.textColor = key.role == .character ? .label : KeyboardDesignTokens.Palette.brandBlue

            secondary.font = KeyboardDesignTokens.Typography.secondary
            secondary.text = key.secondaryLabel
            secondary.textAlignment = .center
            secondary.textColor = isDark ? KeyboardDesignTokens.Palette.ipaSecondaryDark : KeyboardDesignTokens.Palette.ipaSecondaryLight
            secondary.isHidden = key.secondaryLabel.isEmpty

            overlay.backgroundColor = KeyboardDesignTokens.Palette.pressedOverlay
            overlay.layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
            overlay.alpha = 0
            overlay.isUserInteractionEnabled = false

            let stack = UIStackView(arrangedSubviews: [primary, secondary])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 0
            stack.isUserInteractionEnabled = false

            addSubview(stack)
            addSubview(overlay)
            stack.translatesAutoresizingMaskIntoConstraints = false
            overlay.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: centerYAnchor),
                overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                overlay.topAnchor.constraint(equalTo: topAnchor),
                overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            ])

            accessibilityLabel = key.accessibilityLabel
            addTarget(self, action: #selector(touchDown), for: .touchDown)
            addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchCancel, .touchDragExit, .touchUpOutside])
            addTarget(self, action: #selector(tapped), for: .touchUpInside)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = 0.35
            addGestureRecognizer(longPress)
        }

        required init?(coder: NSCoder) { nil }

        @objc private func touchDown() {
            UIView.animate(withDuration: 0.08) {
                self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                self.overlay.alpha = 1
            }
        }
        @objc private func touchUp() {
            UIView.animate(withDuration: 0.12) {
                self.transform = .identity
                self.overlay.alpha = 0
            }
        }
        @objc private func tapped() { onTap?() }
        @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
            guard gr.state == .began, !key.alternatives.isEmpty else { return }
            onLongPress?(self)
        }
    }

    weak var delegate: KeyboardViewDelegate?

    private let lang = Lang.current()
    private var currentMode: InputMode = .candidate
    private var currentPanel: Panel = .letters

    private let rootStack = UIStackView()
    private let previewCard = UIView()
    private let logoView = UIImageView()
    private let ipaResultLabel = UILabel()
    private let ipaResultTitleLabel = UILabel()
    private let codeLabel = UILabel()
    private let codeTitleLabel = UILabel()
    private let divider = UIView()
    private let modePillButton = UIButton(type: .system)

    private let quickStack = UIStackView()
    private let rowsStack = UIStackView()
    private let bottomStack = UIStackView()

    private let shiftButton = UIButton(type: .system)
    private let modeButton = UIButton(type: .system)
    private let backspaceButton = UIButton(type: .system)
    private let symbolToggleButton = UIButton(type: .system)
    private let globeButton = UIButton(type: .system)
    private let spaceButton = UIButton(type: .system)
    private let actionButton = UIButton(type: .system)

    private var alternativeOverlay: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        renderKeys()
        updateBottomAction(.return)
        updateStatus(mode: .candidate, composeBuffer: "", preview: "")
    }

    required init?(coder: NSCoder) { nil }

    func updateBottomAction(_ action: BottomAction) {
        actionButton.setTitle(lang.actionTitle(action), for: .normal)
    }

    func updateCandidates(_ candidates: [String]) {
        // Design稿无独立候选条，候选仅通过顶部结果文本承载
        if let first = candidates.first {
            ipaResultLabel.text = first.components(separatedBy: " [").first ?? first
        }
    }

    func updateStatus(mode: InputMode, composeBuffer: String, preview: String) {
        currentMode = mode
        let input = composeBuffer.isEmpty ? "-" : composeBuffer
        let output = preview.isEmpty ? "-" : preview
        codeLabel.text = input
        ipaResultLabel.text = output

        let title = mode == .candidate ? lang.candidateTitle : lang.dictionaryTitle
        modePillButton.setTitle(title, for: .normal)
        modeButton.setTitle(title, for: .normal)
        renderKeys()
    }

    private func setupUI() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        backgroundColor = isDark ? KeyboardDesignTokens.Palette.backgroundDark : KeyboardDesignTokens.Palette.backgroundLight
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.keyboardHeight).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        setupPreview(isDark: isDark)
        setupQuickIPA()
        setupRows()
        setupBottomTools()
    }

    private func setupPreview(isDark: Bool) {
        previewCard.backgroundColor = isDark ? KeyboardDesignTokens.Palette.previewCardDark : KeyboardDesignTokens.Palette.previewCardLight
        previewCard.layer.cornerRadius = 16

        logoView.contentMode = .scaleAspectFill
        if let img = UIImage(contentsOfFile: "/Users/guohai/Downloads/fe0b7945-1e2d-4dc6-b268-b3c537583231.png") {
            logoView.image = img
        } else {
            logoView.backgroundColor = KeyboardDesignTokens.Palette.brandBlue
        }
        logoView.layer.cornerRadius = 12
        logoView.layer.masksToBounds = true

        ipaResultLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        ipaResultLabel.textColor = KeyboardDesignTokens.Palette.brandBlue
        ipaResultTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        ipaResultTitleLabel.textColor = .secondaryLabel
        ipaResultTitleLabel.text = lang.ipaResultTitle

        codeLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        codeLabel.textColor = .label
        codeTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        codeTitleLabel.textColor = .secondaryLabel
        codeTitleLabel.text = lang.codeTitle

        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)

        modePillButton.setTitle(lang.candidateTitle, for: .normal)
        styleFunctionKey(modePillButton)
        modePillButton.backgroundColor = .clear
        modePillButton.layer.borderWidth = 1
        modePillButton.layer.borderColor = UIColor.separator.withAlphaComponent(0.4).cgColor
        modePillButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        modePillButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidSwitchFeature()
        }, for: .touchUpInside)

        let resultCol = UIStackView(arrangedSubviews: [ipaResultLabel, ipaResultTitleLabel])
        resultCol.axis = .vertical
        resultCol.spacing = 2

        let codeCol = UIStackView(arrangedSubviews: [codeLabel, codeTitleLabel])
        codeCol.axis = .vertical
        codeCol.spacing = 2

        let content = UIStackView(arrangedSubviews: [logoView, resultCol, divider, codeCol, modePillButton])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false

        previewCard.addSubview(content)
        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: 82),
            logoView.heightAnchor.constraint(equalToConstant: 82),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 56),
            modePillButton.widthAnchor.constraint(equalToConstant: 92),
            modePillButton.heightAnchor.constraint(equalToConstant: 56),
            content.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            content.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -12),
            previewCard.heightAnchor.constraint(equalToConstant: 116)
        ])

        rootStack.addArrangedSubview(previewCard)
    }

    private func setupQuickIPA() {
        quickStack.axis = .horizontal
        quickStack.spacing = 6
        quickStack.distribution = .fillEqually

        for ipa in KeyboardLayout.quickIPA {
            let button = makeFunctionButton(title: ipa)
            button.addAction(UIAction { [weak self] _ in self?.delegate?.keyboardViewDidTapQuickIPA(ipa) }, for: .touchUpInside)
            quickStack.addArrangedSubview(button)
        }

        let more = makeFunctionButton(title: "+")
        more.layer.borderWidth = 1
        more.layer.borderColor = UIColor.systemGray3.cgColor
        more.backgroundColor = .clear
        quickStack.addArrangedSubview(more)

        quickStack.heightAnchor.constraint(equalToConstant: 38).isActive = true
        rootStack.addArrangedSubview(quickStack)
    }

    private func setupRows() {
        rowsStack.axis = .vertical
        rowsStack.spacing = 7
        rootStack.addArrangedSubview(rowsStack)
    }

    private func setupBottomTools() {
        bottomStack.axis = .horizontal
        bottomStack.spacing = 6

        symbolToggleButton.setTitle("123", for: .normal)
        symbolToggleButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.currentPanel = self.currentPanel == .letters ? .symbols : .letters
            self.symbolToggleButton.setTitle(self.currentPanel == .letters ? "123" : "ABC", for: .normal)
            self.renderKeys()
            self.delegate?.keyboardViewDidToggleSymbolPanel()
        }, for: .touchUpInside)

        globeButton.setTitle("🌐", for: .normal)
        globeButton.addAction(UIAction { [weak self] _ in self?.delegate?.keyboardViewDidTapNextKeyboard() }, for: .touchUpInside)

        spaceButton.setTitle(lang.spaceTitle, for: .normal)
        spaceButton.addAction(UIAction { [weak self] _ in self?.delegate?.keyboardViewDidTapSpace() }, for: .touchUpInside)

        actionButton.setTitle("return", for: .normal)
        actionButton.addAction(UIAction { [weak self] _ in self?.delegate?.keyboardViewDidTapContextAction() }, for: .touchUpInside)

        [symbolToggleButton, globeButton, spaceButton, actionButton].forEach {
            styleFunctionKey($0)
            $0.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            bottomStack.addArrangedSubview($0)
        }

        symbolToggleButton.widthAnchor.constraint(equalToConstant: 58).isActive = true
        globeButton.widthAnchor.constraint(equalToConstant: 52).isActive = true
        actionButton.widthAnchor.constraint(equalToConstant: 84).isActive = true

        rootStack.addArrangedSubview(bottomStack)
    }

    private func renderKeys() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = currentPanel == .letters ? KeyboardLayout.letterRows : KeyboardLayout.symbolRows

        rows.enumerated().forEach { index, row in
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 6
            stack.distribution = .fillEqually

            if currentPanel == .letters, index == 2 {
                styleFunctionKey(shiftButton)
                shiftButton.setImage(UIImage(systemName: "shift"), for: .normal)
                shiftButton.tintColor = .label
                shiftButton.widthAnchor.constraint(equalToConstant: 54).isActive = true
                stack.addArrangedSubview(shiftButton)
            }

            for key in row {
                let model = modelForKey(key, lettersPanel: currentPanel == .letters)
                let button = KeyboardKeyButton(key: model, isDark: traitCollection.userInterfaceStyle == .dark)
                button.onTap = { [weak self] in
                    guard let self else { return }
                    if self.currentPanel == .letters { self.delegate?.keyboardViewDidTapLetter(model.output) }
                    else { self.delegate?.keyboardViewDidTapPunctuation(model.output) }
                }
                button.onLongPress = { [weak self] source in self?.showAlternatives(from: source) }
                stack.addArrangedSubview(button)
            }

            if currentPanel == .letters, index == 2 {
                styleFunctionKey(modeButton)
                modeButton.setImage(nil, for: .normal)
                modeButton.setTitle(currentMode == .candidate ? lang.candidateTitle : lang.dictionaryTitle, for: .normal)
                modeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
                modeButton.widthAnchor.constraint(equalToConstant: 72).isActive = true
                modeButton.addAction(UIAction { [weak self] _ in self?.delegate?.keyboardViewDidSwitchFeature() }, for: .touchUpInside)
                stack.addArrangedSubview(modeButton)

                styleFunctionKey(backspaceButton)
                backspaceButton.setImage(UIImage(systemName: "delete.left"), for: .normal)
                backspaceButton.tintColor = KeyboardDesignTokens.Palette.brandBlue
                backspaceButton.widthAnchor.constraint(equalToConstant: 54).isActive = true
                backspaceButton.addAction(UIAction { [weak self] _ in self?.delegate?.keyboardViewDidTapBackspace() }, for: .touchUpInside)
                stack.addArrangedSubview(backspaceButton)
            }

            let padded = UIStackView()
            padded.axis = .horizontal
            let lead = UIView()
            let trail = UIView()
            let pad: CGFloat = index == 1 ? 16 : 0
            lead.widthAnchor.constraint(equalToConstant: pad).isActive = true
            trail.widthAnchor.constraint(equalToConstant: pad).isActive = true
            padded.addArrangedSubview(lead)
            padded.addArrangedSubview(stack)
            padded.addArrangedSubview(trail)
            rowsStack.addArrangedSubview(padded)
        }
    }

    private func modelForKey(_ key: String, lettersPanel: Bool) -> KeyModel {
        if !lettersPanel {
            return KeyModel(id: key, primaryLabel: key, secondaryLabel: "", output: key, role: .character, alternatives: [], accessibilityLabel: key)
        }
        let secondary = currentMode == .candidate ? (KeyboardLayout.secondaryIPA[key] ?? "") : key
        let alternatives = KeyboardLayout.alternatives[key] ?? []
        let label = secondary.isEmpty ? key.uppercased() : "\(key.uppercased()), outputs \(secondary)"
        return KeyModel(id: key, primaryLabel: key, secondaryLabel: secondary, output: key, role: .character, alternatives: alternatives, accessibilityLabel: label)
    }

    private func showAlternatives(from source: KeyboardKeyButton) {
        alternativeOverlay?.removeFromSuperview()
        let card = UIView()
        card.backgroundColor = traitCollection.userInterfaceStyle == .dark ? KeyboardDesignTokens.Palette.previewCardDark : .white
        card.layer.cornerRadius = 10
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 3
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        source.key.alternatives.forEach { alt in
            let b = makeFunctionButton(title: alt)
            b.widthAnchor.constraint(equalToConstant: 44).isActive = true
            b.addAction(UIAction { [weak self] _ in
                self?.alternativeOverlay?.removeFromSuperview()
                self?.delegate?.keyboardViewDidSelectAlternative(alt)
            }, for: .touchUpInside)
            row.addArrangedSubview(b)
        }

        addSubview(card)
        let origin = source.convert(source.bounds, to: self)
        let top = max(4, origin.minY - 44)
        let left = max(4, min(bounds.width - CGFloat(max(1, source.key.alternatives.count)) * 50 - 8, origin.minX - 10))

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: left),
            card.topAnchor.constraint(equalTo: topAnchor, constant: top),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 6),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -6),
            card.heightAnchor.constraint(equalToConstant: 44)
        ])
        alternativeOverlay = card
    }

    private func styleFunctionKey(_ button: UIButton) {
        button.backgroundColor = traitCollection.userInterfaceStyle == .dark ? KeyboardDesignTokens.Palette.keySpecialDark : KeyboardDesignTokens.Palette.keySpecialLight
        button.setTitleColor(KeyboardDesignTokens.Palette.brandBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
    }

    private func makeFunctionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        styleFunctionKey(button)
        return button
    }
}
