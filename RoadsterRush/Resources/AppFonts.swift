import SwiftUI

enum AppFonts {
    enum Weight {
        case regular
        case medium
        case semibold
        case bold

        var fontName: String {
            switch self {
            case .regular: "ChakraPetch-Regular"
            case .medium: "ChakraPetch-Medium"
            case .semibold: "ChakraPetch-SemiBold"
            case .bold: "ChakraPetch-Bold"
            }
        }
    }

    static func ui(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .custom(weight.fontName, fixedSize: size)
    }

    static func title(_ size: CGFloat) -> Font {
        .custom("ChakraPetch-BoldItalic", fixedSize: size)
    }

    static func lcd(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Silkscreen-Bold" : "Silkscreen-Regular", fixedSize: size)
    }
}
