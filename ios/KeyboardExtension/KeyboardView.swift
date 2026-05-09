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
        var emptyCodeHint: String {
            switch self { case .zh: return "输入码"; case .ja: return "入力"; case .ko: return "입력"; case .en: return "code" }
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

    private enum FunctionKeyStyle {
        case standard
        case white
        case quick
        case outline
        case action
    }

    private final class BrandLogoView: UIView {
        private let gradient = CAGradientLayer()
        private let symbolLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            translatesAutoresizingMaskIntoConstraints = false
            layer.cornerRadius = 18
            layer.masksToBounds = true

            gradient.colors = [
                KeyboardDesignTokens.Palette.brandBlue.cgColor,
                KeyboardDesignTokens.Palette.brandBlueDeep.cgColor
            ]
            gradient.startPoint = CGPoint(x: 0.05, y: 0.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
            layer.insertSublayer(gradient, at: 0)

            symbolLabel.text = "æ"
            symbolLabel.textAlignment = .center
            symbolLabel.textColor = .white
            symbolLabel.font = .systemFont(ofSize: 52, weight: .bold)
            symbolLabel.adjustsFontSizeToFitWidth = true
            symbolLabel.minimumScaleFactor = 0.65
            symbolLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(symbolLabel)

            NSLayoutConstraint.activate([
                symbolLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
                symbolLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                symbolLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1)
            ])
        }

        required init?(coder: NSCoder) { nil }

        override func layoutSubviews() {
            super.layoutSubviews()
            gradient.frame = bounds
            layer.cornerRadius = min(bounds.width, bounds.height) * 0.22
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
            backgroundColor = isDark ? KeyboardDesignTokens.Palette.keyNormalDark : KeyboardDesignTokens.Palette.keyNormalLight
            layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = isDark ? 0.22 : 0.13
            layer.shadowRadius = 1.2
            layer.shadowOffset = CGSize(width: 0, height: 1.2)

            primary.text = key.primaryLabel
            primary.font = KeyboardDesignTokens.Typography.primary
            primary.textAlignment = .center
            primary.textColor = .label
            primary.adjustsFontSizeToFitWidth = true
            primary.minimumScaleFactor = 0.65

            secondary.text = key.secondaryLabel
            secondary.font = KeyboardDesignTokens.Typography.secondary
            secondary.textAlignment = .center
            secondary.textColor = isDark ? KeyboardDesignTokens.Palette.ipaSecondaryDark : KeyboardDesignTokens.Palette.ipaSecondaryLight
            secondary.isHidden = key.secondaryLabel.isEmpty
            secondary.adjustsFontSizeToFitWidth = true
            secondary.minimumScaleFactor = 0.7

            overlay.backgroundColor = KeyboardDesignTokens.Palette.pressedOverlay
            overlay.layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
            overlay.alpha = 0
            overlay.isUserInteractionEnabled = false

            let stack = UIStackView(arrangedSubviews: [primary, secondary])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = -1
            stack.isUserInteractionEnabled = false
            stack.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stack)
            addSubview(overlay)
            overlay.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: centerYAnchor),
                stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
                overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                overlay.topAnchor.constraint(equalTo: topAnchor),
                overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
                heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.keyHeight)
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
                self.transform = CGAffineTransform(scaleX: 0.965, y: 0.965)
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
    private var composeBuffer = ""
    private var convertedPreview = ""
    private var latestCandidates: [String] = []

    private let rootStack = UIStackView()
    private let previewCard = UIView()
    private let logoView = BrandLogoView()
    private let ipaResultLabel = UILabel()
    private let ipaResultTitleLabel = UILabel()
    private let codeLabel = UILabel()
    private let codeTitleLabel = UILabel()
    private let divider = UIView()
    private let modePillButton = UIButton(type: .system)

    private let quickStack = UIStackView()
    private let rowsStack = UIStackView()
    private let bottomStack = UIStackView()

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyTheme()
        renderKeys()
    }

    func updateBottomAction(_ action: BottomAction) {
        actionButton.setTitle(lang.actionTitle(action), for: .normal)
        styleFunctionKey(actionButton, style: .action)
    }

    func updateCandidates(_ candidates: [String]) {
        latestCandidates = candidates
        refreshPreviewLabels()
    }

    func updateStatus(mode: InputMode, composeBuffer: String, preview: String) {
        let shouldRender = currentMode != mode
        currentMode = mode
        self.composeBuffer = composeBuffer
        self.convertedPreview = preview

        let title = mode == .candidate ? lang.candidateTitle : lang.dictionaryTitle
        modePillButton.setTitle(title, for: .normal)

        refreshPreviewLabels()
        if shouldRender { renderKeys() }
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.keyboardHeight).isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = KeyboardDesignTokens.Metrics.verticalSpacing
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: KeyboardDesignTokens.Metrics.horizontalPadding),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -KeyboardDesignTokens.Metrics.horizontalPadding),
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: KeyboardDesignTokens.Metrics.verticalPadding),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -KeyboardDesignTokens.Metrics.verticalPadding)
        ])

        setupPreview()
        setupQuickIPA()
        setupRows()
        setupBottomTools()
        applyTheme()
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        backgroundColor = isDark ? KeyboardDesignTokens.Palette.backgroundDark : KeyboardDesignTokens.Palette.backgroundLight
        previewCard.backgroundColor = isDark ? KeyboardDesignTokens.Palette.previewCardDark : KeyboardDesignTokens.Palette.previewCardLight
        divider.backgroundColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.16)
        ipaResultTitleLabel.textColor = isDark ? KeyboardDesignTokens.Palette.secondaryTextDark : KeyboardDesignTokens.Palette.secondaryTextLight
        codeTitleLabel.textColor = isDark ? KeyboardDesignTokens.Palette.secondaryTextDark : KeyboardDesignTokens.Palette.secondaryTextLight
        codeLabel.textColor = .label
        ipaResultLabel.textColor = KeyboardDesignTokens.Palette.brandBlue
        styleFunctionKey(modePillButton, style: .outline)
        styleFunctionKey(symbolToggleButton, style: .standard)
        styleFunctionKey(globeButton, style: .standard)
        styleFunctionKey(spaceButton, style: .white)
        styleFunctionKey(actionButton, style: .action)
    }

    private func setupPreview() {
        previewCard.layer.cornerRadius = 20
        previewCard.layer.shadowColor = UIColor.black.cgColor
        previewCard.layer.shadowOpacity = 0.06
        previewCard.layer.shadowRadius = 10
        previewCard.layer.shadowOffset = CGSize(width: 0, height: 5)

        ipaResultLabel.font = KeyboardDesignTokens.Typography.previewValue
        ipaResultLabel.textColor = KeyboardDesignTokens.Palette.brandBlue
        ipaResultLabel.adjustsFontSizeToFitWidth = true
        ipaResultLabel.minimumScaleFactor = 0.68
        ipaResultLabel.lineBreakMode = .byTruncatingTail

        ipaResultTitleLabel.font = KeyboardDesignTokens.Typography.previewCaption
        ipaResultTitleLabel.text = lang.ipaResultTitle

        codeLabel.font = KeyboardDesignTokens.Typography.previewValue
        codeLabel.adjustsFontSizeToFitWidth = true
        codeLabel.minimumScaleFactor = 0.68
        codeLabel.lineBreakMode = .byTruncatingTail

        codeTitleLabel.font = KeyboardDesignTokens.Typography.previewCaption
        codeTitleLabel.text = lang.codeTitle

        modePillButton.setTitle(lang.candidateTitle, for: .normal)
        modePillButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        modePillButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidSwitchFeature()
        }, for: .touchUpInside)

        let resultCol = UIStackView(arrangedSubviews: [ipaResultLabel, ipaResultTitleLabel])
        resultCol.axis = .vertical
        resultCol.spacing = 3
        resultCol.setContentHuggingPriority(.defaultLow, for: .horizontal)
        resultCol.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let codeCol = UIStackView(arrangedSubviews: [codeLabel, codeTitleLabel])
        codeCol.axis = .vertical
        codeCol.spacing = 3
        codeCol.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeCol.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [logoView, resultCol, divider, codeCol, modePillButton])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false

        previewCard.addSubview(content)
        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: 68),
            logoView.heightAnchor.constraint(equalToConstant: 68),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 52),
            modePillButton.widthAnchor.constraint(equalToConstant: 86),
            modePillButton.heightAnchor.constraint(equalToConstant: 56),
            content.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),
            content.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -14),
            previewCard.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.previewHeight)
        ])

        rootStack.addArrangedSubview(previewCard)
    }

    private func setupQuickIPA() {
        quickStack.axis = .horizontal
        quickStack.spacing = KeyboardDesignTokens.Metrics.keySpacing
        quickStack.distribution = .fillEqually

        KeyboardLayout.quickIPA.forEach { ipa in
            let button = makeFunctionButton(title: ipa, style: .quick)
            button.titleLabel?.font = KeyboardDesignTokens.Typography.quickIPA
            button.addAction(UIAction { [weak self] _ in
                self?.delegate?.keyboardViewDidTapQuickIPA(ipa)
            }, for: .touchUpInside)
            quickStack.addArrangedSubview(button)
        }

        let more = makeFunctionButton(title: "+", style: .outline)
        more.titleLabel?.font = .systemFont(ofSize: 26, weight: .semibold)
        more.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.currentPanel = self.currentPanel == .letters ? .symbols : .letters
            self.symbolToggleButton.setTitle(self.currentPanel == .letters ? "123" : "ABC", for: .normal)
            self.renderKeys()
            self.delegate?.keyboardViewDidToggleSymbolPanel()
        }, for: .touchUpInside)
        quickStack.addArrangedSubview(more)

        quickStack.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.quickRowHeight).isActive = true
        rootStack.addArrangedSubview(quickStack)
    }

    private func setupRows() {
        rowsStack.axis = .vertical
        rowsStack.spacing = KeyboardDesignTokens.Metrics.rowSpacing
        rootStack.addArrangedSubview(rowsStack)
    }

    private func setupBottomTools() {
        bottomStack.axis = .horizontal
        bottomStack.spacing = KeyboardDesignTokens.Metrics.keySpacing
        bottomStack.alignment = .fill
        bottomStack.distribution = .fill

        symbolToggleButton.setTitle("123", for: .normal)
        symbolToggleButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.currentPanel = self.currentPanel == .letters ? .symbols : .letters
            self.symbolToggleButton.setTitle(self.currentPanel == .letters ? "123" : "ABC", for: .normal)
            self.renderKeys()
            self.delegate?.keyboardViewDidToggleSymbolPanel()
        }, for: .touchUpInside)

        globeButton.setTitle(nil, for: .normal)
        globeButton.setImage(UIImage(systemName: "globe"), for: .normal)
        globeButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapNextKeyboard()
        }, for: .touchUpInside)

        spaceButton.setTitle(lang.spaceTitle, for: .normal)
        spaceButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapSpace()
        }, for: .touchUpInside)

        actionButton.setTitle(lang.actionTitle(.return), for: .normal)
        actionButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapContextAction()
        }, for: .touchUpInside)

        [symbolToggleButton, globeButton, spaceButton, actionButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.bottomKeyHeight).isActive = true
            bottomStack.addArrangedSubview($0)
        }

        symbolToggleButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        globeButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        actionButton.widthAnchor.constraint(equalToConstant: 96).isActive = true

        rootStack.addArrangedSubview(bottomStack)
    }

    private func renderKeys() {
        rowsStack.arrangedSubviews.forEach { view in
            rowsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let rows = currentPanel == .letters ? KeyboardLayout.letterRows : KeyboardLayout.symbolRows

        for (index, row) in rows.enumerated() {
            let rowContainer = UIStackView()
            rowContainer.axis = .horizontal
            rowContainer.alignment = .fill
            rowContainer.spacing = 0

            let leadingPad = UIView()
            let trailingPad = UIView()
            let pad = rowPadding(for: index, panel: currentPanel)
            leadingPad.widthAnchor.constraint(equalToConstant: pad).isActive = true
            trailingPad.widthAnchor.constraint(equalToConstant: pad).isActive = true

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = KeyboardDesignTokens.Metrics.keySpacing
            rowStack.distribution = .fillEqually

            if currentPanel == .letters, index == 2 {
                let shift = makeIconButton(systemName: "shift", style: .standard)
                rowStack.addArrangedSubview(shift)
            }

            row.forEach { key in
                let model = modelForKey(key, lettersPanel: currentPanel == .letters)
                let button = KeyboardKeyButton(key: model, isDark: traitCollection.userInterfaceStyle == .dark)
                button.onTap = { [weak self] in
                    guard let self else { return }
                    if self.currentPanel == .letters {
                        self.delegate?.keyboardViewDidTapLetter(model.output)
                    } else {
                        self.delegate?.keyboardViewDidTapPunctuation(model.output)
                    }
                }
                button.onLongPress = { [weak self] source in
                    self?.showAlternatives(from: source)
                }
                rowStack.addArrangedSubview(button)
            }

            if currentPanel == .letters, index == 2 {
                let backspace = makeIconButton(systemName: "delete.left", style: .standard)
                backspace.addAction(UIAction { [weak self] _ in
                    self?.delegate?.keyboardViewDidTapBackspace()
                }, for: .touchUpInside)
                rowStack.addArrangedSubview(backspace)
            }

            rowContainer.addArrangedSubview(leadingPad)
            rowContainer.addArrangedSubview(rowStack)
            rowContainer.addArrangedSubview(trailingPad)
            rowsStack.addArrangedSubview(rowContainer)
        }
    }

    private func rowPadding(for index: Int, panel: Panel) -> CGFloat {
        guard panel == .letters else { return index == 2 ? 38 : 0 }
        switch index {
        case 1: return 28
        case 2: return 0
        default: return 0
        }
    }

    private func modelForKey(_ key: String, lettersPanel: Bool) -> KeyModel {
        if !lettersPanel {
            return KeyModel(id: key, primaryLabel: key, secondaryLabel: "", output: key, role: .character, alternatives: [], accessibilityLabel: key)
        }

        let secondary = KeyboardLayout.secondaryIPA[key] ?? ""
        let alternatives = KeyboardLayout.alternatives[key] ?? []
        let label = secondary.isEmpty ? key.uppercased() : "\(key.uppercased()), outputs \(secondary)"
        return KeyModel(id: key, primaryLabel: key, secondaryLabel: secondary, output: key, role: .character, alternatives: alternatives, accessibilityLabel: label)
    }

    private func refreshPreviewLabels() {
        let candidate = latestCandidates.first?.components(separatedBy: " [").first
        let displayResult: String

        if currentMode == .dictionary, let candidate, !candidate.isEmpty, !composeBuffer.isEmpty {
            displayResult = candidate
        } else if !convertedPreview.isEmpty {
            displayResult = convertedPreview
        } else if !composeBuffer.isEmpty {
            displayResult = composeBuffer
        } else {
            displayResult = "æ"
        }

        ipaResultLabel.text = displayResult
        codeLabel.text = composeBuffer.isEmpty ? lang.emptyCodeHint : composeBuffer

        let dim = composeBuffer.isEmpty && convertedPreview.isEmpty && latestCandidates.isEmpty
        ipaResultLabel.alpha = dim ? 0.38 : 1
        codeLabel.alpha = dim ? 0.48 : 1
    }

    private func showAlternatives(from source: KeyboardKeyButton) {
        alternativeOverlay?.removeFromSuperview()

        let card = UIView()
        card.backgroundColor = traitCollection.userInterfaceStyle == .dark ? KeyboardDesignTokens.Palette.previewCardDark : .white
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 5
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        source.key.alternatives.forEach { alt in
            let button = makeFunctionButton(title: alt, style: .quick)
            button.widthAnchor.constraint(equalToConstant: 46).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.alternativeOverlay?.removeFromSuperview()
                self?.delegate?.keyboardViewDidSelectAlternative(alt)
            }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }

        addSubview(card)
        layoutIfNeeded()
        let origin = source.convert(source.bounds, to: self)
        let width = CGFloat(max(1, source.key.alternatives.count)) * 52 + 12
        let left = max(KeyboardDesignTokens.Metrics.horizontalPadding, min(bounds.width - width - KeyboardDesignTokens.Metrics.horizontalPadding, origin.minX - 12))
        let top = max(KeyboardDesignTokens.Metrics.verticalPadding, origin.minY - 50)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: left),
            card.topAnchor.constraint(equalTo: topAnchor, constant: top),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 6),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -6),
            card.heightAnchor.constraint(equalToConstant: 48),
            card.widthAnchor.constraint(equalToConstant: width)
        ])

        alternativeOverlay = card
    }

    private func makeIconButton(systemName: String, style: FunctionKeyStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        styleFunctionKey(button, style: style)
        button.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.keyHeight).isActive = true
        return button
    }

    private func makeFunctionButton(title: String, style: FunctionKeyStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        styleFunctionKey(button, style: style)
        return button
    }

    private func styleFunctionKey(_ button: UIButton, style: FunctionKeyStyle) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        button.layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
        button.layer.masksToBounds = false
        button.layer.borderWidth = 0
        button.layer.borderColor = nil
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.titleLabel?.textAlignment = .center
        button.tintColor = .label
        button.setTitleColor(.label, for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.06
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)

        switch style {
        case .standard:
            button.backgroundColor = isDark ? KeyboardDesignTokens.Palette.keySpecialDark : KeyboardDesignTokens.Palette.keySpecialLight
            button.setTitleColor(.label, for: .normal)
            button.tintColor = .label
            button.titleLabel?.font = KeyboardDesignTokens.Typography.function
        case .white:
            button.backgroundColor = isDark ? KeyboardDesignTokens.Palette.spaceDark : KeyboardDesignTokens.Palette.spaceLight
            button.setTitleColor(.label, for: .normal)
            button.tintColor = .label
            button.titleLabel?.font = KeyboardDesignTokens.Typography.function
        case .quick:
            button.backgroundColor = isDark ? KeyboardDesignTokens.Palette.quickKeyDark : KeyboardDesignTokens.Palette.quickKeyLight
            button.setTitleColor(KeyboardDesignTokens.Palette.brandBlue, for: .normal)
            button.tintColor = KeyboardDesignTokens.Palette.brandBlue
            button.titleLabel?.font = KeyboardDesignTokens.Typography.quickIPA
        case .outline:
            button.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.45)
            button.setTitleColor(KeyboardDesignTokens.Palette.brandBlue, for: .normal)
            button.tintColor = KeyboardDesignTokens.Palette.brandBlue
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            button.layer.borderWidth = 1.2
            button.layer.borderColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.18).cgColor
        case .action:
            button.backgroundColor = KeyboardDesignTokens.Palette.brandBlue
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
            button.titleLabel?.font = KeyboardDesignTokens.Typography.action
            button.layer.shadowOpacity = 0.18
            button.layer.shadowRadius = 3
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }
}
