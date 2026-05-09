import UIKit

enum KeyboardDesignTokens {
    enum Palette {
        static let brandBlue = UIColor(hex: 0x2F6BFF)
        static let brandBlueDeep = UIColor(hex: 0x0F4FE8)
        static let brandCyan = UIColor(hex: 0x48D8FF)

        static let backgroundLight = UIColor(hex: 0xEEF3F9)
        static let backgroundDark = UIColor(hex: 0x101827)

        static let previewCardLight = UIColor.white.withAlphaComponent(0.96)
        static let previewCardDark = UIColor(hex: 0x182131).withAlphaComponent(0.96)

        static let keyNormalLight = UIColor.white.withAlphaComponent(0.98)
        static let keyNormalDark = UIColor(hex: 0x222B3A)

        static let keySpecialLight = UIColor(hex: 0xD9E1EC)
        static let keySpecialDark = UIColor(hex: 0x2B3546)

        static let quickKeyLight = UIColor.white.withAlphaComponent(0.82)
        static let quickKeyDark = UIColor(hex: 0x1D2A3D)

        static let spaceLight = UIColor.white.withAlphaComponent(0.98)
        static let spaceDark = UIColor(hex: 0x202938)

        static let ipaSecondaryLight = UIColor(hex: 0x155DFF)
        static let ipaSecondaryDark = UIColor(hex: 0x8AB4FF)

        static let secondaryTextLight = UIColor(hex: 0x7C8798)
        static let secondaryTextDark = UIColor(hex: 0x9CA3AF)

        static let pressedOverlay = UIColor.black.withAlphaComponent(0.08)
    }

    enum Metrics {
        static let keyboardHeight: CGFloat = 424
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 8
        static let verticalSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 7
        static let keySpacing: CGFloat = 7
        static let keyHeight: CGFloat = 52
        static let bottomKeyHeight: CGFloat = 54
        static let keyCorner: CGFloat = 11
        static let previewHeight: CGFloat = 100
        static let quickRowHeight: CGFloat = 50
    }

    enum Typography {
        static let primary = UIFont.systemFont(ofSize: 28, weight: .semibold)
        static let secondary = UIFont.systemFont(ofSize: 13, weight: .medium)
        static let function = UIFont.systemFont(ofSize: 20, weight: .medium)
        static let action = UIFont.systemFont(ofSize: 21, weight: .semibold)
        static let previewValue = UIFont.systemFont(ofSize: 24, weight: .semibold)
        static let previewCaption = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let quickIPA = UIFont.systemFont(ofSize: 25, weight: .semibold)
    }
}

private extension UIColor {
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1.0
        )
    }
}
