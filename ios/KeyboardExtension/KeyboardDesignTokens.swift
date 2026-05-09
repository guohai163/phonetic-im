import UIKit

/// 键盘扩展使用的设计令牌：颜色、尺寸与字体。
enum KeyboardDesignTokens {
    /// 调色板定义（含浅色/深色主题）。
    enum Palette {
        static let brandBlue = UIColor(hex: 0x2F6BFF)
        static let brandBlueDeep = UIColor(hex: 0x0F4FE8)
        static let brandCyan = UIColor(hex: 0x48D8FF)

        static let backgroundLight = UIColor(hex: 0xF2F6FB)
        static let backgroundDark = UIColor(hex: 0x101827)

        static let previewCardLight = UIColor.white.withAlphaComponent(0.98)
        static let previewCardDark = UIColor(hex: 0x182131).withAlphaComponent(0.98)

        static let keyNormalLight = UIColor.white.withAlphaComponent(0.98)
        static let keyNormalDark = UIColor(hex: 0x222B3A)

        static let keySpecialLight = UIColor(hex: 0xDCE5F0)
        static let keySpecialDark = UIColor(hex: 0x2B3546)

        static let quickKeyLight = UIColor.white.withAlphaComponent(0.96)
        static let quickKeyDark = UIColor(hex: 0x1D2A3D)

        static let spaceLight = UIColor.white.withAlphaComponent(0.99)
        static let spaceDark = UIColor(hex: 0x202938)

        static let ipaSecondaryLight = UIColor(hex: 0x155DFF)
        static let ipaSecondaryDark = UIColor(hex: 0x8AB4FF)

        static let secondaryTextLight = UIColor(hex: 0x667085)
        static let secondaryTextDark = UIColor(hex: 0x9CA3AF)

        static let pressedOverlay = UIColor.black.withAlphaComponent(0.08)
    }

    /// 布局与控件尺寸常量。
    enum Metrics {
        static let keyboardHeight: CGFloat = 302
        static let horizontalPadding: CGFloat = 4
        static let verticalPadding: CGFloat = 6
        static let verticalSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 8
        static let keySpacing: CGFloat = 6
        static let keyHeight: CGFloat = 44
        static let bottomKeyHeight: CGFloat = 44
        static let keyCorner: CGFloat = 6
        static let previewHeight: CGFloat = 68

        static let previewLogoSize: CGFloat = 50
        static let previewLogoCorner: CGFloat = 13
        static let previewPillWidth: CGFloat = 72
        static let previewPillHeight: CGFloat = 40
        static let sideFunctionKeyWidth: CGFloat = 44
        static let bottomSmallKeyWidth: CGFloat = 56
        static let bottomActionWidth: CGFloat = 96
        static let secondRowPadding: CGFloat = 18
    }

    /// 字体层级定义。
    enum Typography {
        static let primary = UIFont.systemFont(ofSize: 24, weight: .medium)
        static let secondary = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let function = UIFont.systemFont(ofSize: 18, weight: .regular)
        static let action = UIFont.systemFont(ofSize: 19, weight: .semibold)
        static let previewValue = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let previewCaption = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let quickIPA = UIFont.systemFont(ofSize: 22, weight: .semibold)
    }
}

private extension UIColor {
    /// 通过 16 进制 RGB 值构造纯色。
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1.0
        )
    }
}
