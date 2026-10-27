import RealityKit
import simd

// Endless road from road.dart: segments share one mesh and leapfrog ahead of the car.
final class Road {
    let root = Entity()
    private var segments: [ModelEntity] = []
    private var segmentZ: [Double] = []

    init(materials: MaterialFactory) throws {
        let half = Float(RoadLayout.halfWidth)
        let length = Float(RoadLayout.segmentLength)
        let lane = Float(RoadLayout.laneWidth)
        let asphalt: UInt32 = 0, grass: UInt32 = 1, white: UInt32 = 2, pole: UInt32 = 3, lamp: UInt32 = 4

        var builder = MeshBuilder()
        builder.addPlane(center: .zero, width: half * 2, depth: length, part: asphalt)
        builder.addPlane(center: [-half - 30, 0, 0], width: 60, depth: length, part: grass)
        builder.addPlane(center: [half + 30, 0, 0], width: 60, depth: length, part: grass)
        for x in [-half + 0.3, half - 0.3] {
            builder.addPlane(center: [x, 0.01, 0], width: 0.18, depth: length, part: white)
        }
        for x in [-lane / 2, lane / 2] {
            var z = -length / 2 + 2.5
            while z < length / 2 {
                builder.addPlane(center: [x, 0.01, -z], width: 0.16, depth: 3, part: white)
                z += 8
            }
        }
        for side: Float in [-1, 1] {
            let x = side * (half + 0.8)
            builder.addFrustum(center: [x, 2.5, 0], bottomRadius: 0.08, topRadius: 0.06, height: 5, segments: 10, part: pole)
            builder.addBox(center: [x - side * 0.6, 5, 0], size: [1.4, 0.1, 0.1], part: pole)
            builder.addBox(center: [x - side * 1.1, 4.92, 0], size: [0.5, 0.08, 0.25], part: lamp)
        }
        let mesh = try builder.makeMesh(name: "road")
        let palette: [any Material] = [
            materials.paint([0.12, 0.12, 0.13], roughness: 0.85),
            materials.paint([0.16, 0.42, 0.14], roughness: 1),
            materials.paint([0.9, 0.9, 0.9], roughness: 0.7),
            materials.paint([0.6, 0.6, 0.62], metallic: 0.8, roughness: 0.4),
            materials.glow([1, 0.85, 0.6], strength: 4),
        ]

        for i in 0..<RoadLayout.segmentCount {
            let segment = ModelEntity(mesh: mesh, materials: palette)
            segment.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(segment)
            segments.append(segment)
            segmentZ.append(0)
            place(i, z: Double(i) * RoadLayout.segmentLength)
        }
    }

    func reset() {
        for i in segments.indices {
            place(i, z: Double(i) * RoadLayout.segmentLength)
        }
    }

    func follow(_ playerZ: Double) {
        for i in segments.indices where segmentZ[i] + RoadLayout.segmentLength / 2 < playerZ - 20 {
            place(i, z: segmentZ[i] + RoadLayout.segmentLength * Double(RoadLayout.segmentCount))
        }
    }

    private func place(_ index: Int, z: Double) {
        segmentZ[index] = z
        segments[index].position = GameSpace.world(0, 0, z)
    }
}
