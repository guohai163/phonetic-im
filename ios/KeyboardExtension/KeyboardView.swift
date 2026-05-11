import UIKit

/// 键盘主视图对控制器暴露的交互回调。
protocol KeyboardViewDelegate: AnyObject {
    func keyboardViewDidTapLetter(_ letter: String)
    func keyboardViewDidTapCandidate(_ candidate: String)
    func keyboardViewDidTapBackspace()
    func keyboardViewDidTapSpace()
    func keyboardViewDidTapReturn()
    func keyboardViewDidTapPunctuation(_ punctuation: String)
    func keyboardViewDidSwitchFeature()
    func keyboardViewDidToggleSymbolPanel()
    func keyboardViewDidTapContextAction()
    func keyboardViewDidTapModifier(_ value: String)

    func keyboardViewDidSelectAlternative(_ value: String)
}

/// 键盘扩展的主界面，负责按键渲染、预览展示与交互转发。
final class KeyboardView: UIView {
    /// 当前按键面板类型（字母/符号）。
    enum Panel { case letters, symbols }
    /// 底部右侧动作键语义（跟随宿主输入框 ReturnKeyType）。
    enum BottomAction { case none, send, `return`, done, go, search, next }

    /// 本地化文案集合，根据系统首选语言选择。
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
        var emptyValueHint: String { "—" }
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

    /// 功能键样式类型。
    private enum FunctionKeyStyle {
        case standard
        case white
        case quick
        case outline
        case action
    }

    /// 预览卡片左侧品牌标识视图（优先展示 AppLogo，缺失时回退占位样式）。
    private final class BrandLogoView: UIView {
        private let imageView = UIImageView()
        private let fallbackContainer = UIView()
        private let fallbackLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            translatesAutoresizingMaskIntoConstraints = false
            layer.cornerRadius = KeyboardDesignTokens.Metrics.previewLogoCorner
            layer.masksToBounds = true

            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            addSubview(imageView)

            fallbackContainer.translatesAutoresizingMaskIntoConstraints = false
            fallbackContainer.backgroundColor = KeyboardDesignTokens.Palette.brandBlue
            addSubview(fallbackContainer)

            fallbackLabel.text = "æ"
            fallbackLabel.textAlignment = .center
            fallbackLabel.textColor = .white
            fallbackLabel.font = .systemFont(ofSize: 30, weight: .bold)
            fallbackLabel.adjustsFontSizeToFitWidth = true
            fallbackLabel.minimumScaleFactor = 0.6
            fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
            fallbackContainer.addSubview(fallbackLabel)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

                fallbackContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
                fallbackContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
                fallbackContainer.topAnchor.constraint(equalTo: topAnchor),
                fallbackContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

                fallbackLabel.leadingAnchor.constraint(equalTo: fallbackContainer.leadingAnchor, constant: 4),
                fallbackLabel.trailingAnchor.constraint(equalTo: fallbackContainer.trailingAnchor, constant: -4),
                fallbackLabel.centerYAnchor.constraint(equalTo: fallbackContainer.centerYAnchor)
            ])

            reloadLogo()
        }

        required init?(coder: NSCoder) { nil }

        private func reloadLogo() {
            let extBundle = Bundle(for: BrandLogoView.self)
            let logo =
                UIImage(named: "AppLogo", in: extBundle, compatibleWith: nil) ??
                UIImage(named: "AppLogo", in: .main, compatibleWith: nil) ??
                UIImage(named: "AppLogo")
            imageView.image = logo
            imageView.isHidden = logo == nil
            fallbackContainer.isHidden = logo != nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = min(bounds.width, bounds.height) * 0.26
            fallbackContainer.layer.cornerRadius = layer.cornerRadius
        }
    }



    /// 字母/符号按键视图，支持点击与长按候选。
    private final class KeyboardKeyButton: UIControl {
        let key: KeyModel
        private let primary = UILabel()
        private let secondary = UILabel()
        private let overlay = UIView()
        var onTap: (() -> Void)?
        var onLongPress: ((KeyboardKeyButton) -> Void)?
        var onLongPressStateChanged: ((KeyboardKeyButton, UILongPressGestureRecognizer) -> Void)?

        init(key: KeyModel, isDark: Bool) {
            self.key = key
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            backgroundColor = isDark ? KeyboardDesignTokens.Palette.keyNormalDark : KeyboardDesignTokens.Palette.keyNormalLight
            layer.cornerRadius = KeyboardDesignTokens.Metrics.keyCorner
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = isDark ? 0.18 : 0.08
            layer.shadowRadius = 0.8
            layer.shadowOffset = CGSize(width: 0, height: 1.0)

            primary.text = key.primaryLabel
            primary.font = KeyboardDesignTokens.Typography.primary
            primary.textAlignment = .center
            primary.textColor = .label
            primary.adjustsFontSizeToFitWidth = true
            primary.minimumScaleFactor = 0.62

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
                stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
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
            guard !key.alternatives.isEmpty else { return }
            if gr.state == .began {
                onLongPress?(self)
            }
            onLongPressStateChanged?(self, gr)
        }
    }

    weak var delegate: KeyboardViewDelegate?

    private let lang = Lang.current()
    private var currentMode: InputMode = .candidate
    private var currentPanel: Panel = .letters
    private var composeBuffer = ""
    private var convertedPreview = ""
    private var latestCandidates: [String] = []

    /// 当前候选列表的只读访问（供控制器获取首候选等场景使用）。
    var currentCandidates: [String] { latestCandidates }

    private let rootStack = UIStackView()
    private let previewCard = UIView()
    private let logoView = BrandLogoView()
    private let ipaResultLabel = UILabel()
    private let ipaResultTitleLabel = UILabel()
    private let codeLabel = UILabel()
    private let codeTitleLabel = UILabel()
    private let divider = UIView()
    private let modePillButton = UIButton(type: .system)


    private let rowsStack = UIStackView()
    private let bottomStack = UIStackView()

    private let symbolToggleButton = UIButton(type: .system)
    private let spaceButton = UIButton(type: .system)
    private let actionButton = UIButton(type: .system)

    private var alternativeOverlay: UIView?
    private var alternativeOptionButtons: [UIButton] = []
    private var alternativeOptionValues: [String] = []
    private var highlightedAlternativeIndex: Int?
    private var isAlternativeTrackingActive = false
    private var isModifierAlternativeTracking = false

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

    /// 更新底部动作键标题与视觉样式。
    func updateBottomAction(_ action: BottomAction) {
        actionButton.setTitle(lang.actionTitle(action), for: .normal)
        styleFunctionKey(actionButton, style: .action)
    }

    /// 更新候选列表并刷新预览文案。
    func updateCandidates(_ candidates: [String]) {
        latestCandidates = candidates
        refreshPreviewLabels()
    }

    /// 更新输入模式与预览状态；模式切换时会重绘按键区。
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
        codeLabel.textColor = isDark ? .white : UIColor(hexForKeyboardView: 0x0B1736)
        ipaResultLabel.textColor = KeyboardDesignTokens.Palette.brandBlue
        styleFunctionKey(modePillButton, style: .outline)
        styleFunctionKey(symbolToggleButton, style: .standard)
        styleFunctionKey(spaceButton, style: .white)
        styleFunctionKey(actionButton, style: .action)
    }

    private func setupPreview() {
        previewCard.layer.cornerRadius = 16
        previewCard.layer.shadowColor = UIColor.black.cgColor
        previewCard.layer.shadowOpacity = 0.05
        previewCard.layer.shadowRadius = 8
        previewCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        ipaResultLabel.font = KeyboardDesignTokens.Typography.previewValue
        ipaResultLabel.textColor = KeyboardDesignTokens.Palette.brandBlue
        ipaResultLabel.adjustsFontSizeToFitWidth = true
        ipaResultLabel.minimumScaleFactor = 0.58
        ipaResultLabel.lineBreakMode = .byTruncatingTail

        ipaResultTitleLabel.font = KeyboardDesignTokens.Typography.previewCaption
        ipaResultTitleLabel.text = lang.ipaResultTitle

        codeLabel.font = KeyboardDesignTokens.Typography.previewValue
        codeLabel.adjustsFontSizeToFitWidth = true
        codeLabel.minimumScaleFactor = 0.58
        codeLabel.lineBreakMode = .byTruncatingTail

        codeTitleLabel.font = KeyboardDesignTokens.Typography.previewCaption
        codeTitleLabel.text = lang.codeTitle

        modePillButton.setTitle(lang.candidateTitle, for: .normal)
        modePillButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
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

        logoView.setContentHuggingPriority(.required, for: .horizontal)
        logoView.setContentCompressionResistancePriority(.required, for: .horizontal)
        modePillButton.setContentHuggingPriority(.required, for: .horizontal)
        modePillButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        divider.setContentHuggingPriority(.required, for: .horizontal)
        divider.setContentCompressionResistancePriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [logoView, resultCol, divider, codeCol, modePillButton])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false

        previewCard.addSubview(content)
        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.previewLogoSize),
            logoView.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.previewLogoSize),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 50),
            modePillButton.widthAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.previewPillWidth),
            modePillButton.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.previewPillHeight),
            resultCol.widthAnchor.constraint(equalTo: codeCol.widthAnchor),
            content.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            content.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 10),
            content.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -10),
            previewCard.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.previewHeight)
        ])

        rootStack.addArrangedSubview(previewCard)
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

        spaceButton.setTitle(lang.spaceTitle, for: .normal)
        spaceButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapSpace()
        }, for: .touchUpInside)

        actionButton.setTitle(lang.actionTitle(.return), for: .normal)
        actionButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapContextAction()
        }, for: .touchUpInside)

        [symbolToggleButton, spaceButton, actionButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.bottomKeyHeight).isActive = true
            bottomStack.addArrangedSubview($0)
        }

        symbolToggleButton.widthAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.bottomSmallKeyWidth).isActive = true
        actionButton.widthAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.bottomActionWidth).isActive = true

        rootStack.addArrangedSubview(bottomStack)
    }

    /// 根据当前面板（字母/符号）重新构建按键行。
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
            rowContainer.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.keyHeight).isActive = true

            let leadingPad = UIView()
            let trailingPad = UIView()
            let pad = rowPadding(for: index, panel: currentPanel)
            leadingPad.widthAnchor.constraint(equalToConstant: pad).isActive = true
            trailingPad.widthAnchor.constraint(equalToConstant: pad).isActive = true

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .fill
            rowStack.spacing = KeyboardDesignTokens.Metrics.keySpacing
            rowStack.distribution = .fill

            var characterButtons: [UIView] = []

            if currentPanel == .letters, index == 2 {
                let modifier = makeModifierKey()
                modifier.widthAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.sideFunctionKeyWidth).isActive = true
                rowStack.addArrangedSubview(modifier)
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
                characterButtons.append(button)
            }

            if currentPanel == .letters, index == 2 {
                let backspace = makeIconButton(systemName: "delete.left", style: .standard)
                backspace.addAction(UIAction { [weak self] _ in
                    self?.delegate?.keyboardViewDidTapBackspace()
                }, for: .touchUpInside)
                backspace.widthAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.sideFunctionKeyWidth).isActive = true
                rowStack.addArrangedSubview(backspace)
            }

            equalizeWidths(characterButtons)

            rowContainer.addArrangedSubview(leadingPad)
            rowContainer.addArrangedSubview(rowStack)
            rowContainer.addArrangedSubview(trailingPad)
            rowsStack.addArrangedSubview(rowContainer)
        }
    }

    /// 计算指定行在当前面板中的左右占位宽度。
    private func rowPadding(for index: Int, panel: Panel) -> CGFloat {
        guard panel == .letters else { return index == 2 ? KeyboardDesignTokens.Metrics.sideFunctionKeyWidth : 0 }
        switch index {
        case 1: return KeyboardDesignTokens.Metrics.secondRowPadding
        case 2: return 0
        default: return 0
        }
    }

    /// 将同一行字符按键宽度约束为一致。
    private func equalizeWidths(_ views: [UIView]) {
        guard let first = views.first else { return }
        views.dropFirst().forEach { view in
            view.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
        }
    }

    /// 生成按键模型（字母面板包含 IPA 次标与长按替代项）。
    private func modelForKey(_ key: String, lettersPanel: Bool) -> KeyModel {
        if !lettersPanel {
            return KeyModel(id: key, primaryLabel: key, secondaryLabel: "", output: key, role: .character, alternatives: [], accessibilityLabel: key)
        }

        let secondary = KeyboardLayout.secondaryIPA[key] ?? ""
        let alternatives = KeyboardLayout.alternatives[key] ?? []
        let label = secondary.isEmpty ? key.uppercased() : "\(key.uppercased()), outputs \(secondary)"
        return KeyModel(id: key, primaryLabel: key, secondaryLabel: secondary, output: key, role: .character, alternatives: alternatives, accessibilityLabel: label)
    }

    /// 刷新预览卡片中的 IPA 结果与输入码展示。
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
            displayResult = lang.emptyValueHint
        }

        ipaResultLabel.text = displayResult
        codeLabel.text = composeBuffer.isEmpty ? lang.emptyValueHint : composeBuffer

        let dim = composeBuffer.isEmpty && convertedPreview.isEmpty && latestCandidates.isEmpty
        ipaResultLabel.alpha = dim ? 0.55 : 1
        codeLabel.alpha = dim ? 0.55 : 1
    }

    /// 在长按按键上方弹出替代音标面板。
    private func showAlternatives(from source: KeyboardKeyButton, trackingMode: Bool = false) {
        alternativeOverlay?.removeFromSuperview()
        alternativeOptionButtons = []
        alternativeOptionValues = source.key.alternatives
        highlightedAlternativeIndex = nil

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
            button.isUserInteractionEnabled = !trackingMode
            if !trackingMode {
                button.addAction(UIAction { [weak self] _ in
                    self?.hideAlternativeOverlay()
                    self?.delegate?.keyboardViewDidSelectAlternative(alt)
                }, for: .touchUpInside)
            }
            row.addArrangedSubview(button)
            alternativeOptionButtons.append(button)
        }

        addSubview(card)
        layoutIfNeeded()
        let origin = source.convert(source.bounds, to: self)
        let width = CGFloat(max(1, source.key.alternatives.count)) * 52 + 12
        let left = max(KeyboardDesignTokens.Metrics.horizontalPadding, min(bounds.width - width - KeyboardDesignTokens.Metrics.horizontalPadding, origin.minX - 12))
        let top = max(KeyboardDesignTokens.Metrics.verticalPadding, origin.minY - 54)

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

    private func hideAlternativeOverlay() {
        alternativeOverlay?.removeFromSuperview()
        alternativeOverlay = nil
        alternativeOptionButtons = []
        alternativeOptionValues = []
        highlightedAlternativeIndex = nil
        isAlternativeTrackingActive = false
        isModifierAlternativeTracking = false
    }

    private func beginAlternativeTracking(from source: KeyboardKeyButton) {
        showAlternatives(from: source, trackingMode: true)
        isAlternativeTrackingActive = true
        isModifierAlternativeTracking = true
    }

    private func updateAlternativeTracking(location: CGPoint) {
        guard isAlternativeTrackingActive else { return }
        var newIndex: Int?
        for (index, button) in alternativeOptionButtons.enumerated() {
            let point = button.convert(location, from: self)
            if button.bounds.contains(point) {
                newIndex = index
                break
            }
        }
        guard newIndex != highlightedAlternativeIndex else { return }
        setHighlightedAlternativeIndex(newIndex)
    }

    private func endAlternativeTracking(commit: Bool) {
        let valueToCommit: String?
        if commit, let idx = highlightedAlternativeIndex, idx < alternativeOptionValues.count {
            valueToCommit = alternativeOptionValues[idx]
        } else {
            valueToCommit = nil
        }
        hideAlternativeOverlay()
        if let valueToCommit {
            delegate?.keyboardViewDidSelectAlternative(valueToCommit)
        }
    }

    private func setHighlightedAlternativeIndex(_ index: Int?) {
        highlightedAlternativeIndex = index
        for (i, button) in alternativeOptionButtons.enumerated() {
            let selected = (i == index)
            if selected {
                button.backgroundColor = KeyboardDesignTokens.Palette.brandBlue
                button.setTitleColor(.white, for: .normal)
                button.tintColor = .white
            } else {
                styleFunctionKey(button, style: .quick)
            }
        }
    }

    private func makeIconButton(systemName: String, style: FunctionKeyStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        styleFunctionKey(button, style: style)
        button.heightAnchor.constraint(equalToConstant: KeyboardDesignTokens.Metrics.keyHeight).isActive = true
        return button
    }

    /// 生成第三行左侧的修饰符键：点击主重音、长按候选、滑动快捷。
    private func makeModifierKey() -> KeyboardKeyButton {
        let model = KeyModel(
            id: "modifier_shift_replacement",
            primaryLabel: KeyboardLayout.modifierPrimary,
            secondaryLabel: KeyboardLayout.modifierSecondary,
            output: KeyboardLayout.modifierPrimary,
            role: .special,
            alternatives: KeyboardLayout.modifierAlternatives,
            accessibilityLabel: "stress mark key"
        )

        let button = KeyboardKeyButton(key: model, isDark: traitCollection.userInterfaceStyle == .dark)
        styleModifierKey(button)
        button.onTap = { [weak self] in
            guard let self, !self.isModifierAlternativeTracking else { return }
            self.delegate?.keyboardViewDidTapModifier(KeyboardLayout.modifierPrimary)
        }
        button.onLongPressStateChanged = { [weak self] source, gesture in
            guard let self else { return }
            switch gesture.state {
            case .began:
                self.beginAlternativeTracking(from: source)
                self.updateAlternativeTracking(location: gesture.location(in: self))
            case .changed:
                self.updateAlternativeTracking(location: gesture.location(in: self))
            case .ended:
                self.updateAlternativeTracking(location: gesture.location(in: self))
                self.endAlternativeTracking(commit: true)
            case .cancelled, .failed:
                self.endAlternativeTracking(commit: false)
            default:
                break
            }
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleModifierPan(_:)))
        pan.cancelsTouchesInView = true
        button.addGestureRecognizer(pan)

        return button
    }

    @objc private func handleModifierPan(_ gr: UIPanGestureRecognizer) {
        guard !isModifierAlternativeTracking else { return }
        guard gr.state == .ended else { return }
        let t = gr.translation(in: self)
        let threshold: CGFloat = 16
        var output: String?

        if abs(t.y) > abs(t.x), t.y < -threshold {
            output = "ˌ"
        } else if t.x > threshold {
            output = "ː"
        } else if t.x < -threshold {
            output = "."
        }

        guard let value = output else { return }
        delegate?.keyboardViewDidTapModifier(value)
    }

    private func styleModifierKey(_ button: UIControl) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        button.backgroundColor = isDark ? KeyboardDesignTokens.Palette.keySpecialDark : KeyboardDesignTokens.Palette.keySpecialLight
    }

    private func makeFunctionButton(title: String, style: FunctionKeyStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        styleFunctionKey(button, style: style)
        return button
    }

    private func styleFunctionKey(_ button: UIButton, style: FunctionKeyStyle) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        button.layer.cornerRadius = style == .outline ? 14 : KeyboardDesignTokens.Metrics.keyCorner
        button.layer.masksToBounds = false
        button.layer.borderWidth = 0
        button.layer.borderColor = nil
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.titleLabel?.textAlignment = .center
        button.tintColor = .label
        button.setTitleColor(.label, for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowRadius = 0.8
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)

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
            button.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.55)
            button.setTitleColor(KeyboardDesignTokens.Palette.brandBlue, for: .normal)
            button.tintColor = KeyboardDesignTokens.Palette.brandBlue
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.layer.borderWidth = 1.2
            button.layer.borderColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.18).cgColor
            button.layer.shadowOpacity = 0.04
        case .action:
            button.backgroundColor = KeyboardDesignTokens.Palette.brandBlue
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
            button.titleLabel?.font = KeyboardDesignTokens.Typography.action
            button.layer.shadowOpacity = 0.15
            button.layer.shadowRadius = 2
            button.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        }
    }
}

private extension UIColor {
    /// 通过 16 进制 RGB 值构造 `KeyboardView` 内部专用颜色。
    convenience init(hexForKeyboardView hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1.0
        )
    }
}
