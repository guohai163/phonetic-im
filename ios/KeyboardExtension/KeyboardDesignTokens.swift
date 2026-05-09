import UIKit

enum KeyboardDesignTokens {
    enum Palette {
        static let backgroundLight = UIColor(hex: 0xEEF2F7)
        static let backgroundDark = UIColor(hex: 0x111827)
        static let keyNormalLight = UIColor.white
        static let keyNormalDark = UIColor(hex: 0x1F2937)
        static let keySpecialLight = UIColor(hex: 0xE6F0FF)
        static let keySpecialDark = UIColor(hex: 0x1E3A8A)
        static let brandBlue = UIColor(hex: 0x2F6BFF)
        static let ipaSecondaryLight = UIColor(hex: 0x4A6FAE)
        static let ipaSecondaryDark = UIColor(hex: 0x93C5FD)
        static let pressedOverlay = UIColor.black.withAlphaComponent(0.08)
        static let previewCardLight = UIColor.white.withAlphaComponent(0.92)
        static let previewCardDark = UIColor(hex: 0x0F172A).withAlphaComponent(0.95)
    }

    enum Metrics {
        static let keyboardHeight: CGFloat = 304
        static let horizontalPadding: CGFloat = 8
        static let verticalSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 7
        static let keyHeight: CGFloat = 46
        static let keyCorner: CGFloat = 10
        static let previewHeight: CGFloat = 46
        static let quickRowHeight: CGFloat = 36
    }

    enum Typography {
        static let primary = UIFont.systemFont(ofSize: 27, weight: .semibold)
        static let secondary = UIFont.systemFont(ofSize: 11.5, weight: .medium)
        static let function = UIFont.systemFont(ofSize: 20, weight: .medium)
        static let preview = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let capsule = UIFont.systemFont(ofSize: 12, weight: .semibold)
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
