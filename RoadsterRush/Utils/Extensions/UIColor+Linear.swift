import UIKit

extension UIColor {
    // The Flutter scene colors are linear; UIColor expects sRGB-encoded components.
    convenience init(linear color: SIMD3<Float>, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat(Self.srgb(color.x)),
            green: CGFloat(Self.srgb(color.y)),
            blue: CGFloat(Self.srgb(color.z)),
            alpha: alpha
        )
    }

    static func srgb(_ linear: Float) -> Float {
        let c = min(max(linear, 0), 1)
        return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
    }
}
