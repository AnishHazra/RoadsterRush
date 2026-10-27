import CoreGraphics
import os
import RealityKit
import UIKit

// Gradient sky from gradient_sky in the Flutter scene, baked into an equirectangular skybox.
enum SkyEnvironment {
    static let zenith = SIMD3<Float>(0.12, 0.32, 0.75)
    static let horizon = SIMD3<Float>(0.75, 0.82, 0.92)

    static func make() async -> EnvironmentResource? {
        guard let image = gradientImage(width: 256, height: 128) else { return nil }
        do {
            return try await EnvironmentResource(equirectangular: image, withName: "sky")
        } catch {
            Logger(subsystem: "RoadsterRush", category: "Sky").error("Sky failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func gradientImage(width: Int, height: Int) -> CGImage? {
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for row in 0..<height {
            let elevation = 0.5 - (Float(row) + 0.5) / Float(height)
            let t = pow(max(0, elevation * 2), 0.55)
            let color = horizon + (zenith - horizon) * t
            let encoded = SIMD3<UInt8>(
                UInt8(UIColor.srgb(color.x) * 255),
                UInt8(UIColor.srgb(color.y) * 255),
                UInt8(UIColor.srgb(color.z) * 255)
            )
            for column in 0..<width {
                let i = (row * width + column) * 4
                pixels[i] = encoded.x
                pixels[i + 1] = encoded.y
                pixels[i + 2] = encoded.z
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
