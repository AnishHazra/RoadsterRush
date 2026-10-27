import Metal
import os
import RealityKit
import UIKit

// Lit materials go through the fog surface shader; falls back to plain PBR if Metal isn't available.
final class MaterialFactory {
    private let logger = Logger(subsystem: "RoadsterRush", category: "Materials")
    private let fogShader: CustomMaterial.SurfaceShader?

    init() {
        if let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary() {
            fogShader = CustomMaterial.SurfaceShader(named: "foggedSurface", in: library)
        } else {
            fogShader = nil
        }
    }

    func paint(_ color: SIMD3<Float>, metallic: Float = 0, roughness: Float = 0.6) -> any Material {
        if let fogShader {
            do {
                var material = try CustomMaterial(surfaceShader: fogShader, lightingModel: .lit)
                material.baseColor = .init(tint: UIColor(linear: color))
                material.metallic = .init(scale: metallic)
                material.roughness = .init(scale: roughness)
                material.specular = .init(scale: 0.5)
                material.faceCulling = .none
                return material
            } catch {
                logger.error("Fog material failed: \(error.localizedDescription)")
            }
        }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(linear: color))
        material.metallic = .init(scale: metallic)
        material.roughness = .init(scale: roughness)
        material.faceCulling = .none
        return material
    }

    func glow(_ color: SIMD3<Float>, strength: Float) -> any Material {
        if let fogShader {
            do {
                var material = try CustomMaterial(surfaceShader: fogShader, lightingModel: .lit)
                material.baseColor = .init(tint: .black)
                material.emissiveColor = .init(color: UIColor(linear: color))
                material.roughness = .init(scale: 1)
                material.metallic = .init(scale: 0)
                material.custom.value = SIMD4<Float>(strength, 0, 0, 0)
                material.faceCulling = .none
                return material
            } catch {
                logger.error("Glow material failed: \(error.localizedDescription)")
            }
        }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .black)
        material.emissiveColor = .init(color: UIColor(linear: color))
        material.emissiveIntensity = strength
        material.faceCulling = .none
        return material
    }

    func unlit(_ color: SIMD3<Float>) -> UnlitMaterial {
        var material = UnlitMaterial(color: UIColor(linear: color))
        material.faceCulling = .none
        return material
    }
}
