import os
import RealityKit
import simd

final class PlayerCar {
    static let width: Float = 2.0
    static let length: Float = 4.5

    let entity = Entity()
    let thrusters: Thrusters
    private static let pivot = SIMD3<Float>(0, 0.6, 0)

    init(model: Entity?, materials: MaterialFactory) throws {
        if let model {
            entity.addChild(Self.fitted(model))
            entity.addChild(try CarBuilder.launchLights(materials: materials))
        } else {
            entity.addChild(try CarBuilder.buildCar(materials: materials))
        }
        thrusters = try Thrusters(car: entity, materials: materials)
    }

    var rotation: simd_quatf { entity.orientation }

    func place(x: Double, y: Double, z: Double, roll: Double, pitch: Double) {
        let rotation = simd_quatf(angle: Float(-pitch), axis: [1, 0, 0]) * simd_quatf(angle: Float(roll), axis: [0, 0, 1])
        entity.position = GameSpace.world(x, y, z) + Self.pivot - rotation.act(Self.pivot)
        entity.orientation = rotation
    }

    // Uniformly scales any model into the 2.0 x 4.5 m footprint, resting on y = 0, nose toward -z.
    private static func fitted(_ model: Entity) -> Entity {
        let holder = Entity()
        let scaler = Entity()
        holder.addChild(scaler)
        scaler.addChild(model)

        var bounds = model.visualBounds(relativeTo: holder)
        if bounds.extents.x > bounds.extents.z {
            scaler.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            bounds = model.visualBounds(relativeTo: holder)
        }
        guard bounds.extents.x > 0, bounds.extents.z > 0 else { return holder }
        let scale = min(width / bounds.extents.x, length / bounds.extents.z)
        scaler.scale = SIMD3(repeating: scale)
        scaler.position = -scale * SIMD3(bounds.center.x, bounds.min.y, bounds.center.z)
        return holder
    }
}
