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
}

final class KeyboardView: UIView {
    enum Panel {
        case letters
        case symbols
    }

    enum BottomAction {
        case none
        case send
        case `return`
        case done
        case go
        case search
        case next
    }

    private enum Lang {
        case zh, ja, ko, en

        static func current() -> Lang {
            let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if code.hasPrefix("zh") { return .zh }
            if code.hasPrefix("ja") { return .ja }
            if code.hasPrefix("ko") { return .ko }
            return .en
        }

        func text(inputCode: String, hint: String, candidate: String) -> (String, String, String) {
            switch self {
            case .zh:
                return ("输入码: \(inputCode)", "提示: \(hint)", "候选: \(candidate)")
            case .ja:
                return ("入力コード: \(inputCode)", "ヒント: \(hint)", "候補: \(candidate)")
            case .ko:
                return ("입력 코드: \(inputCode)", "힌트: \(hint)", "후보: \(candidate)")
            case .en:
                return ("Input: \(inputCode)", "Hint: \(hint)", "Candidate: \(candidate)")
            }
        }

        var spaceTitle: String {
            switch self {
            case .zh: return "空格"
            case .ja: return "スペース"
            case .ko: return "공백"
            case .en: return "space"
            }
        }

        func actionTitle(_ action: BottomAction) -> String {
            switch (self, action) {
            case (_, .none): return ""
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

    weak var delegate: KeyboardViewDelegate?

    private let statusLabel = UILabel()
    private let hintLabel = UILabel()
    private let candidateLabel = UILabel()
    private let candidateStack = UIStackView()
    private let rowsStack = UIStackView()
    private let toolsStack = UIStackView()

    private var symbolButton = UIButton(type: .system)
    private var spaceButton = UIButton(type: .system)
    private var actionButton = UIButton(type: .system)
    private var actionButtonWidthConstraint: NSLayoutConstraint?
    private weak var featureToggleButton: UIButton?

    private var currentPanel: Panel = .letters
    private var currentMode: InputMode = .candidate
    private var currentBottomAction: BottomAction = .none
    private let lang = Lang.current()

    private let letterRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]

    private let symbolRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'", "#"]
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        renderRows()
        updateCandidates([])
        updateStatus(mode: .candidate, composeBuffer: "", preview: "")
        updateBottomAction(.none)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBottomAction(_ action: BottomAction) {
        currentBottomAction = action
        actionButton.setTitle(lang.actionTitle(action), for: .normal)
        actionButton.isHidden = action == .none
        actionButtonWidthConstraint?.constant = action == .none ? 0 : 96
    }

    func updateCandidates(_ candidates: [String]) {
        candidateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if candidates.isEmpty {
            candidateLabel.text = lang.text(inputCode: "-", hint: "", candidate: "-").2
            return
        }

        candidateLabel.text = lang.text(inputCode: "-", hint: "", candidate: "").2
        for candidate in candidates.prefix(4) {
            let button = makeKeyButton(title: candidate, role: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            button.addAction(UIAction { [weak self] _ in
                self?.delegate?.keyboardViewDidTapCandidate(candidate)
            }, for: .touchUpInside)
            candidateStack.addArrangedSubview(button)
        }
    }

    func updateStatus(mode: InputMode, composeBuffer: String, preview: String) {
        currentMode = mode
        symbolButton.setTitle(currentPanel == .letters ? "#+=" : "ABC", for: .normal)
        spaceButton.setTitle(lang.spaceTitle, for: .normal)
        featureToggleButton?.setTitle(currentMode == .candidate ? featureTitleCandidate() : featureTitleDictionary(), for: .normal)

        let input = composeBuffer.isEmpty ? "-" : composeBuffer
        let hint = composeBuffer.isEmpty ? "th dh sh zh ng ch" : preview
        let labels = lang.text(inputCode: input, hint: hint, candidate: "-")
        statusLabel.text = labels.0
        hintLabel.text = labels.1

        if candidateStack.arrangedSubviews.isEmpty {
            candidateLabel.text = labels.2
        }
    }

    private func setupLayout() {
        backgroundColor = UIColor(red: 0.83, green: 0.84, blue: 0.87, alpha: 1.0)

        let main = UIStackView()
        main.axis = .vertical
        main.spacing = 8
        main.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)

        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .secondaryLabel

        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel

        candidateLabel.font = .systemFont(ofSize: 13)
        candidateLabel.textColor = .secondaryLabel

        candidateStack.axis = .horizontal
        candidateStack.spacing = 6
        candidateStack.distribution = .fillEqually

        rowsStack.axis = .vertical
        rowsStack.spacing = 8

        toolsStack.axis = .horizontal
        toolsStack.spacing = 6
        toolsStack.distribution = .fill

        [statusLabel, hintLabel, candidateLabel, candidateStack, rowsStack, toolsStack].forEach {
            main.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            main.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            main.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            main.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        addToolButtons()
    }

    private func renderRows() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let first = makeStandardRow(keys: currentPanel == .letters ? letterRows[0] : symbolRows[0], sidePadding: 0)
        let second = makeStandardRow(keys: currentPanel == .letters ? letterRows[1] : symbolRows[1], sidePadding: 20)
        rowsStack.addArrangedSubview(first)
        rowsStack.addArrangedSubview(second)

        if currentPanel == .letters {
            rowsStack.addArrangedSubview(makeLettersThirdRow())
        } else {
            rowsStack.addArrangedSubview(makeSymbolsThirdRow())
        }
    }

    private func makeStandardRow(keys: [String], sidePadding: CGFloat) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually

        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 0

        if sidePadding > 0 {
            let lead = UIView()
            lead.widthAnchor.constraint(equalToConstant: sidePadding).isActive = true
            container.addArrangedSubview(lead)
        }
        container.addArrangedSubview(row)
        if sidePadding > 0 {
            let trail = UIView()
            trail.widthAnchor.constraint(equalToConstant: sidePadding).isActive = true
            container.addArrangedSubview(trail)
        }

        for key in keys {
            let button = makeKeyButton(title: key, role: .normal)
            button.addAction(UIAction { [weak self] _ in
                self?.handleKeyTap(key)
            }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }

        return container
    }

    private func makeLettersThirdRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6

        let left = makeKeyButton(title: currentMode == .candidate ? featureTitleCandidate() : featureTitleDictionary(), role: .function)
        featureToggleButton = left
        left.widthAnchor.constraint(equalToConstant: 88).isActive = true
        left.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidSwitchFeature()
        }, for: .touchUpInside)

        let right = makeKeyButton(title: "⌫", role: .function)
        right.widthAnchor.constraint(equalToConstant: 52).isActive = true
        right.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapBackspace()
        }, for: .touchUpInside)

        row.addArrangedSubview(left)

        let letters = UIStackView()
        letters.axis = .horizontal
        letters.spacing = 6
        letters.distribution = .fillEqually
        row.addArrangedSubview(letters)

        for key in letterRows[2] {
            let button = makeKeyButton(title: key, role: .normal)
            button.addAction(UIAction { [weak self] _ in
                self?.delegate?.keyboardViewDidTapLetter(key)
            }, for: .touchUpInside)
            letters.addArrangedSubview(button)
        }

        row.addArrangedSubview(right)
        return row
    }

    private func makeSymbolsThirdRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6

        let left = makeKeyButton(title: currentMode == .candidate ? featureTitleCandidate() : featureTitleDictionary(), role: .function)
        featureToggleButton = left
        left.widthAnchor.constraint(equalToConstant: 88).isActive = true
        left.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidSwitchFeature()
        }, for: .touchUpInside)
        row.addArrangedSubview(left)

        let symbols = UIStackView()
        symbols.axis = .horizontal
        symbols.spacing = 6
        symbols.distribution = .fillEqually
        row.addArrangedSubview(symbols)

        for key in symbolRows[2] {
            let button = makeKeyButton(title: key, role: .normal)
            button.addAction(UIAction { [weak self] _ in
                self?.delegate?.keyboardViewDidTapPunctuation(key)
            }, for: .touchUpInside)
            symbols.addArrangedSubview(button)
        }

        let right = makeKeyButton(title: "⌫", role: .function)
        right.widthAnchor.constraint(equalToConstant: 52).isActive = true
        right.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapBackspace()
        }, for: .touchUpInside)
        row.addArrangedSubview(right)
        return row
    }

    private func handleKeyTap(_ key: String) {
        if currentPanel == .letters {
            delegate?.keyboardViewDidTapLetter(key)
        } else {
            delegate?.keyboardViewDidTapPunctuation(key)
        }
    }


    private func featureTitleCandidate() -> String {
        switch lang {
        case .zh: return "直输"
        case .ja: return "直輸"
        case .ko: return "직입"
        case .en: return "Direct"
        }
    }

    private func featureTitleDictionary() -> String {
        switch lang {
        case .zh: return "词典"
        case .ja: return "辞書"
        case .ko: return "사전"
        case .en: return "Dictionary"
        }
    }

    private func addToolButtons() {
        symbolButton = makeKeyButton(title: "#+=", role: .function)
        symbolButton.widthAnchor.constraint(equalToConstant: 92).isActive = true
        symbolButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.currentPanel = self.currentPanel == .letters ? .symbols : .letters
            self.renderRows()
            self.delegate?.keyboardViewDidToggleSymbolPanel()
        }, for: .touchUpInside)

        spaceButton = makeKeyButton(title: lang.spaceTitle, role: .normal)
        spaceButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapSpace()
        }, for: .touchUpInside)

        actionButton = makeKeyButton(title: "", role: .function)
        actionButtonWidthConstraint = actionButton.widthAnchor.constraint(equalToConstant: 96)
        actionButtonWidthConstraint?.isActive = true
        actionButton.isHidden = true
        actionButton.addAction(UIAction { [weak self] _ in
            self?.delegate?.keyboardViewDidTapContextAction()
        }, for: .touchUpInside)

        [symbolButton, spaceButton, actionButton].forEach { button in
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            toolsStack.addArrangedSubview(button)
        }
    }

    private enum KeyRole {
        case normal
        case function
    }

    private func makeKeyButton(title: String, role: KeyRole) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        button.layer.cornerRadius = 9
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true

        switch role {
        case .normal:
            button.backgroundColor = .white
        case .function:
            button.backgroundColor = UIColor(red: 0.66, green: 0.69, blue: 0.74, alpha: 1.0)
        }
        return button
    }
}
