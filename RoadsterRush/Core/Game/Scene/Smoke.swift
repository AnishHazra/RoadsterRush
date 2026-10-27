import CoreGraphics
import Foundation
import os
import RealityKit
import UIKit

// Pooled see-through puffs from smoke.dart, drawn as camera-facing soft discs.
final class Smoke {
    private struct Puff {
        let entity: ModelEntity
        var velocity: SIMD3<Float> = .zero
        var age: Float = 1
        var life: Float = 1
        var size: Float = 1
    }

    let root = Entity()
    private var puffs: [Puff] = []
    private var next = 0

    init(count: Int = 260) {
        let mesh = MeshResource.generatePlane(width: 1, height: 1)
        let material = Self.material()
        for _ in 0..<count {
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.components.set(BillboardComponent())
            entity.components.set(OpacityComponent(opacity: 0))
            entity.components.set(DynamicLightShadowComponent(castsShadow: false))
            entity.isEnabled = false
            root.addChild(entity)
            puffs.append(Puff(entity: entity))
        }
    }

    func emit(at position: SIMD3<Float>, velocity: SIMD3<Float>, size: Float) {
        guard !puffs.isEmpty else { return }
        let jitter = SIMD3<Float>(.random(in: -0.5..<0.5), .random(in: -0.5..<0.5), .random(in: -0.5..<0.5))
        puffs[next].age = 0
        puffs[next].life = 0.7 + .random(in: 0..<0.5)
        puffs[next].size = size * (0.8 + .random(in: 0..<0.4))
        puffs[next].velocity = velocity + jitter * 1.5
        puffs[next].entity.position = position
        puffs[next].entity.isEnabled = true
        next = (next + 1) % puffs.count
    }

    func tick(_ dt: Float) {
        for i in puffs.indices where puffs[i].age < puffs[i].life {
            puffs[i].age += dt
            let t = puffs[i].age / puffs[i].life
            let entity = puffs[i].entity
            if t >= 1 {
                entity.isEnabled = false
                continue
            }
            puffs[i].velocity *= max(0, 1 - dt * 3)
            puffs[i].velocity.y += dt * 1.2
            entity.position += puffs[i].velocity * dt
            entity.scale = SIMD3(repeating: puffs[i].size * (0.4 + t * 1.8))
            entity.components[OpacityComponent.self]?.opacity = 0.55 * (1 - t) * (1 - t)
        }
    }

    func clear() {
        for i in puffs.indices {
            puffs[i].age = puffs[i].life
            puffs[i].entity.isEnabled = false
        }
    }

    private static func material() -> UnlitMaterial {
        var material = UnlitMaterial(color: UIColor(white: 0.93, alpha: 1))
        if let image = softDisc(size: 64) {
            do {
                let texture = try TextureResource(image: image, options: .init(semantic: .color))
                material.color = .init(tint: UIColor(white: 0.93, alpha: 1), texture: .init(texture))
            } catch {
                Logger(subsystem: "RoadsterRush", category: "Smoke").error("Smoke texture failed: \(error.localizedDescription)")
            }
        }
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        return material
    }

    private static func softDisc(size: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        let colors = [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 0.6), CGColor(gray: 1, alpha: 0)] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.45, 1]) else {
            return nil
        }
        let center = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: CGFloat(size) / 2, options: [])
        return context.makeImage()
    }
}
