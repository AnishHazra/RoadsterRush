import RealityKit

// Checkered start/finish line with an overhead gantry and five red start lights.
enum StartLine {
    static func make(materials: MaterialFactory) throws -> ModelEntity {
        let white: UInt32 = 0, black: UInt32 = 1, steel: UInt32 = 2, light: UInt32 = 3
        let half = Float(RoadLayout.halfWidth)
        let square: Float = 0.6

        var builder = MeshBuilder()
        let columns = Int((half * 2 / square).rounded())
        for row in 0..<2 {
            for column in 0..<columns {
                let x = -half + square * (Float(column) + 0.5)
                let z = square * (Float(row) - 0.5)
                builder.addPlane(center: [x, 0.012, z], width: square, depth: square, part: (row + column) % 2 == 0 ? white : black)
            }
        }

        for side: Float in [-1, 1] {
            builder.addBox(center: [side * (half + 0.8), 3.4, 0], size: [0.35, 6.8, 0.35], part: steel)
        }
        builder.addBox(center: [0, 6.6, 0], size: [half * 2 + 2, 0.9, 0.5], part: black)
        for i in 0..<5 {
            let x = (Float(i) - 2) * 0.9
            builder.addBox(center: [x, 6.6, 0.27], size: [0.5, 0.5, 0.08], part: light)
        }

        let entity = ModelEntity(mesh: try builder.makeMesh(name: "startLine"), materials: [
            materials.paint([0.9, 0.9, 0.9], roughness: 0.7),
            materials.paint([0.02, 0.02, 0.02], roughness: 0.6),
            materials.paint([0.6, 0.6, 0.62], metallic: 0.8, roughness: 0.4),
            materials.glow([1, 0.03, 0.03], strength: 4),
        ])
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        return entity
    }
}
