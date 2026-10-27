import Foundation
import RealityKit
import simd

final class Jet {
    let flame: ModelEntity
    let origin: SIMD3<Float>
    let direction: SIMD3<Float>
    var power: Float = 0

    init(flame: ModelEntity, origin: SIMD3<Float>, direction: SIMD3<Float>) {
        self.flame = flame
        self.origin = origin
        self.direction = direction
    }
}

// Lift flames under the car plus the side and roll jets from car_builder.dart Thrusters.
final class Thrusters {
    private(set) var jets: [Jet] = []
    private var flames: [ModelEntity] = []
    private var left: [Jet] = []
    private var right: [Jet] = []
    private var lift: [Jet] = []
    private var drop: [Jet] = []

    init(car: Entity, materials: MaterialFactory) throws {
        var nozzles = MeshBuilder()
        var flameShape = MeshBuilder()
        flameShape.addFrustum(center: .zero, bottomRadius: 0, topRadius: 0.14, height: 1, segments: 12, part: 0)
        var jetShape = MeshBuilder()
        jetShape.addFrustum(center: .zero, bottomRadius: 0, topRadius: 0.16, height: 1, segments: 12, part: 0)
        let flameMesh = try flameShape.makeMesh(name: "flame")
        let jetMesh = try jetShape.makeMesh(name: "jetFlame")
        let flameColor = materials.unlit([0.45, 0.75, 1.0])
        let jetColor = materials.unlit([0.6, 0.85, 1.0])

        for x: Float in [-0.55, 0.55] {
            for z: Float in [-1.6, 0, 1.6] {
                nozzles.addFrustum(center: [x, 0.28, z], bottomRadius: 0.12, topRadius: 0.16, height: 0.12, segments: 12, part: 0)
                let flame = Self.flameEntity(mesh: flameMesh, material: flameColor)
                flame.position = [x, 0.22, z]
                car.addChild(flame)
                flames.append(flame)
            }
        }

        func jet(_ origin: SIMD3<Float>, _ direction: SIMD3<Float>) -> Jet {
            let facing = Self.facing(direction)
            nozzles.addFrustum(center: origin, bottomRadius: 0.1, topRadius: 0.14, height: 0.1, segments: 12, rotation: facing, part: 0)
            let flame = Self.flameEntity(mesh: jetMesh, material: jetColor)
            flame.orientation = facing
            car.addChild(flame)
            let made = Jet(flame: flame, origin: origin, direction: direction)
            jets.append(made)
            return made
        }

        for side: Float in [-1, 1] {
            for z: Float in [-1.1, 1.1] {
                let made = jet([side * 1.0, 0.5, z], [side, 0, 0])
                if side < 0 { left.append(made) } else { right.append(made) }
            }
            for z: Float in [-0.6, 0.6] {
                let up = jet([side * 0.95, 0.84, z], [0, 1, 0])
                let down = jet([side * 0.95, 0.16, z], [0, -1, 0])
                // Positive torque fires left-up and right-down; negative fires the opposite pair.
                if side < 0 {
                    lift.append(up)
                    drop.append(down)
                } else {
                    lift.append(down)
                    drop.append(up)
                }
            }
        }

        let nozzleEntity = ModelEntity(
            mesh: try nozzles.makeMesh(name: "nozzles"),
            materials: [materials.paint([0.15, 0.15, 0.16], metallic: 1, roughness: 0.3)]
        )
        car.addChild(nozzleEntity)
    }

    func set(power: Float, push: Float, torque: Float, time: Float) {
        let on = power > 0.02
        for (i, flame) in flames.enumerated() {
            flame.isEnabled = on
            guard on else { continue }
            let flicker = 0.85 + 0.15 * sin(time * 60 + Float(i) * 1.7)
            let length = (0.3 + power * 1.1) * flicker
            flame.scale = SIMD3(repeating: length)
            flame.position.y = 0.22 - length * 0.5
        }
        for jet in left { jet.power = max(0, push) }
        for jet in right { jet.power = max(0, -push) }
        for jet in lift { jet.power = max(0, torque) }
        for jet in drop { jet.power = max(0, -torque) }
        for (i, jet) in jets.enumerated() {
            let visible = jet.power > 0.05
            jet.flame.isEnabled = visible
            guard visible else { continue }
            let flicker = 0.8 + 0.2 * sin(time * 70 + Float(i) * 2.3)
            let length = (0.4 + jet.power * 1.5) * flicker
            jet.flame.scale = SIMD3(repeating: length)
            jet.flame.position = jet.origin + jet.direction * (length * 0.5)
        }
    }

    private static func flameEntity(mesh: MeshResource, material: UnlitMaterial) -> ModelEntity {
        let flame = ModelEntity(mesh: mesh, materials: [material])
        flame.components.set(DynamicLightShadowComponent(castsShadow: false))
        flame.isEnabled = false
        return flame
    }

    // The flame mesh points along -y; turn it to fire along `direction`.
    private static func facing(_ direction: SIMD3<Float>) -> simd_quatf {
        if direction.y > 0.99 { return simd_quatf(angle: .pi, axis: [0, 0, 1]) }
        return simd_quatf(from: [0, -1, 0], to: simd_normalize(direction))
    }
}
