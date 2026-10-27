import RealityKit
import simd

// Endless road from road.dart, lined with grandstands and city blocks.
// Segments leapfrog ahead of the car; a few layout variants hide the repetition.
final class Road {
    let root = Entity()
    private var segments: [ModelEntity] = []
    private var segmentZ: [Double] = []
    private var crowds: [(ModelEntity, ModelEntity)] = []
    private static let variantCount = 3

    init(materials: MaterialFactory) throws {
        let length = Float(RoadLayout.segmentLength)
        let base = Self.roadMesh(length: length)
        let palette = Self.roadMaterials(materials) + Roadside.sceneryMaterials(materials)
        let crowdPalette = Roadside.crowdMaterials(materials)

        var variants: [(MeshResource, MeshResource, MeshResource)] = []
        for variant in 0..<Self.variantCount {
            var random = SeededRandom(seed: UInt64(variant + 1) * 7919)
            var builder = base
            Roadside.addScenery(to: &builder, firstPart: 5, length: length, random: &random)
            let crowd = Roadside.crowd(random: &random)
            variants.append((
                try builder.makeMesh(name: "road\(variant)"),
                try crowd[0].makeMesh(name: "crowdA\(variant)"),
                try crowd[1].makeMesh(name: "crowdB\(variant)")
            ))
        }

        for i in 0..<RoadLayout.segmentCount {
            let (mesh, crowdA, crowdB) = variants[i % Self.variantCount]
            let segment = ModelEntity(mesh: mesh, materials: palette)
            let groupA = ModelEntity(mesh: crowdA, materials: crowdPalette)
            let groupB = ModelEntity(mesh: crowdB, materials: crowdPalette)
            for entity in [segment, groupA, groupB] {
                entity.components.set(DynamicLightShadowComponent(castsShadow: false))
            }
            segment.addChild(groupA)
            segment.addChild(groupB)
            root.addChild(segment)
            segments.append(segment)
            crowds.append((groupA, groupB))
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

    // Spectators bounce in two alternating halves; `excitement` (0...1) makes them jump higher.
    func cheer(time: Float, excitement: Float) {
        let lift = 0.03 + 0.09 * excitement
        for (i, crowd) in crowds.enumerated() {
            let wave = sin(time * 7 + Float(i) * 1.3)
            crowd.0.position.y = max(0, wave) * lift
            crowd.1.position.y = max(0, -wave) * lift
        }
    }

    private func place(_ index: Int, z: Double) {
        segmentZ[index] = z
        segments[index].position = GameSpace.world(0, 0, z)
    }

    private static func roadMesh(length: Float) -> MeshBuilder {
        let half = Float(RoadLayout.halfWidth)
        let lane = Float(RoadLayout.laneWidth)
        let asphalt: UInt32 = 0, grass: UInt32 = 1, white: UInt32 = 2, pole: UInt32 = 3, lamp: UInt32 = 4

        var builder = MeshBuilder()
        builder.addPlane(center: .zero, width: half * 2, depth: length, part: asphalt)
        builder.addPlane(center: [-half - 1.2, 0, 0], width: 2.4, depth: length, part: grass)
        builder.addPlane(center: [half + 1.2, 0, 0], width: 2.4, depth: length, part: grass)
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
        return builder
    }

    private static func roadMaterials(_ materials: MaterialFactory) -> [any Material] {
        [
            materials.paint([0.12, 0.12, 0.13], roughness: 0.85),
            materials.paint([0.16, 0.42, 0.14], roughness: 1),
            materials.paint([0.9, 0.9, 0.9], roughness: 0.7),
            materials.paint([0.6, 0.6, 0.62], metallic: 0.8, roughness: 0.4),
            materials.glow([1, 0.85, 0.6], strength: 4),
        ]
    }
}
