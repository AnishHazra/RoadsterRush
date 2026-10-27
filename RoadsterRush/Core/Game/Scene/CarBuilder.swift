import RealityKit
import simd

// Port of car_builder.dart buildCar() / addLaunchLights(). Station z values are game space (front = +z).
enum CarBuilder {
    private struct Station {
        let z: Float
        let bottom: Float
        let top: Float
        let width: Float
        let topWidth: Float
    }

    private static let body = smooth([
        Station(z: 2.2, bottom: 0.24, top: 0.5, width: 0.62, topWidth: 0.5),
        Station(z: 2.0, bottom: 0.22, top: 0.6, width: 0.86, topWidth: 0.72),
        Station(z: 1.4, bottom: 0.2, top: 0.72, width: 0.97, topWidth: 0.8),
        Station(z: 0.7, bottom: 0.2, top: 0.76, width: 0.95, topWidth: 0.8),
        Station(z: -0.3, bottom: 0.2, top: 0.8, width: 0.94, topWidth: 0.8),
        Station(z: -1.3, bottom: 0.2, top: 0.84, width: 1.0, topWidth: 0.84),
        Station(z: -1.95, bottom: 0.24, top: 0.8, width: 0.94, topWidth: 0.8),
        Station(z: -2.2, bottom: 0.32, top: 0.7, width: 0.8, topWidth: 0.68),
    ], steps: 4)

    private static let cabin = smooth([
        Station(z: 0.95, bottom: 0.7, top: 0.71, width: 0.78, topWidth: 0.76),
        Station(z: 0.35, bottom: 0.7, top: 1.0, width: 0.8, topWidth: 0.6),
        Station(z: -0.25, bottom: 0.72, top: 1.14, width: 0.82, topWidth: 0.56),
        Station(z: -0.9, bottom: 0.74, top: 1.1, width: 0.82, topWidth: 0.56),
        Station(z: -1.55, bottom: 0.78, top: 0.9, width: 0.8, topWidth: 0.6),
        Station(z: -1.95, bottom: 0.78, top: 0.8, width: 0.74, topWidth: 0.62),
    ], steps: 4)

    static func buildCar(materials: MaterialFactory) throws -> ModelEntity {
        var builder = MeshBuilder()
        loft(body, into: &builder, part: 0)
        loft(cabin, into: &builder, part: 1)
        for x: Float in [-0.58, 0.58] {
            builder.addBox(center: [x, 0.6, -1.97], size: [0.38, 0.06, 0.18], part: 2)
        }
        builder.addBox(center: [0, 0.66, 2.2], size: [1.5, 0.06, 0.06], part: 3)
        let sideways = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        for x: Float in [-0.84, 0.84] {
            for z: Float in [-1.35, 1.4] {
                builder.addFrustum(center: [x, 0.36, -z], bottomRadius: 0.36, topRadius: 0.36, height: 0.28, segments: 24, rotation: sideways, part: 4)
                builder.addFrustum(center: [x, 0.36, -z], bottomRadius: 0.24, topRadius: 0.24, height: 0.3, segments: 18, rotation: sideways, part: 5)
            }
        }
        return ModelEntity(mesh: try builder.makeMesh(name: "fallbackCar"), materials: [
            materials.paint([0.9, 0.9, 0.92], metallic: 0.7, roughness: 0.22),
            materials.paint([0.03, 0.04, 0.06], metallic: 0.2, roughness: 0.1),
            materials.glow([1, 0.95, 0.85], strength: 3),
            materials.glow([1, 0.02, 0.02], strength: 2),
            materials.paint([0.04, 0.04, 0.04], roughness: 0.9),
            materials.paint([0.15, 0.15, 0.16], metallic: 1, roughness: 0.3),
        ])
    }

    static func launchLights(materials: MaterialFactory) throws -> ModelEntity {
        var builder = MeshBuilder()
        builder.addBox(center: [0, 0.82, 2.24], size: [1.7, 0.05, 0.05], part: 0)
        builder.addBox(center: [0, 0.5, -2.24], size: [1.2, 0.03, 0.04], part: 1)
        let entity = ModelEntity(mesh: try builder.makeMesh(name: "launchLights"), materials: [
            materials.glow([1, 0.02, 0.02], strength: 4),
            materials.glow([0.9, 0.95, 1], strength: 4),
        ])
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        return entity
    }

    private static func spline(_ a: Float, _ b: Float, _ c: Float, _ d: Float, _ t: Float) -> Float {
        let t2 = t * t
        let t3 = t2 * t
        return 0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
    }

    private static func smooth(_ keys: [Station], steps: Int) -> [Station] {
        var out: [Station] = []
        for i in 0..<(keys.count - 1) {
            let a = keys[max(i - 1, 0)]
            let b = keys[i]
            let c = keys[i + 1]
            let d = keys[min(i + 2, keys.count - 1)]
            for s in 0..<steps {
                let t = Float(s) / Float(steps)
                out.append(Station(
                    z: spline(a.z, b.z, c.z, d.z, t),
                    bottom: spline(a.bottom, b.bottom, c.bottom, d.bottom, t),
                    top: spline(a.top, b.top, c.top, d.top, t),
                    width: spline(a.width, b.width, c.width, d.width, t),
                    topWidth: spline(a.topWidth, b.topWidth, c.topWidth, d.topWidth, t)
                ))
            }
        }
        if let last = keys.last { out.append(last) }
        return out
    }

    private static func ring(_ s: Station) -> [SIMD3<Float>] {
        let mid = s.bottom + (s.top - s.bottom) * 0.55
        let low = s.bottom + (s.top - s.bottom) * 0.12
        let points: [SIMD2<Float>] = [
            [s.width * 0.86, s.bottom],
            [s.width, low],
            [s.width, mid],
            [s.topWidth, s.top - (s.top - mid) * 0.25],
            [s.topWidth * 0.55, s.top],
            [-s.topWidth * 0.55, s.top],
            [-s.topWidth, s.top - (s.top - mid) * 0.25],
            [-s.width, mid],
            [-s.width, low],
            [-s.width * 0.86, s.bottom],
        ]
        return points.map { SIMD3($0.x, $0.y, -s.z) }
    }

    private static func loft(_ stations: [Station], into builder: inout MeshBuilder, part: UInt32) {
        let rings = stations.map { ring($0) }
        for i in 0..<(rings.count - 1) {
            let r0 = rings[i]
            let r1 = rings[i + 1]
            let center = SIMD3<Float>(0, (stations[i].bottom + stations[i].top) / 2, -(stations[i].z + stations[i + 1].z) / 2)
            for j in r0.indices {
                let k = (j + 1) % r0.count
                let outward = (r0[j] + r0[k] + r1[j] + r1[k]) * 0.25 - center
                builder.addTriangle(r0[j], r0[k], r1[k], outward: outward, part: part)
                builder.addTriangle(r0[j], r1[k], r1[j], outward: outward, part: part)
            }
        }
        for end in [0, rings.count - 1] {
            let ring = rings[end]
            let center = SIMD3<Float>(0, (stations[end].bottom + stations[end].top) / 2, -stations[end].z)
            let outward = SIMD3<Float>(0, 0, end == 0 ? -1 : 1)
            for j in ring.indices {
                builder.addTriangle(center, ring[j], ring[(j + 1) % ring.count], outward: outward, part: part)
            }
        }
    }
}
