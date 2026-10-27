import RealityKit
import simd

// Grandstands with spectators and a city skyline on both sides of a road segment.
enum Roadside {
    enum Part: UInt32, CaseIterable {
        case pavement
        case concrete
        case seats
        case barrier
        case stripe
        case roof
        case glass
        case stoneA
        case stoneB
        case stoneC
        case stoneD
    }

    private static let standStart: Float = 7.6
    private static let tierDepth: Float = 1.3
    private static let tierCount = 4
    private static let standLength: Float = 32

    private static let shirts: [SIMD3<Float>] = [
        [0.7, 0.05, 0.05],
        [0.05, 0.2, 0.7],
        [0.9, 0.65, 0.05],
        [0.85, 0.85, 0.85],
        [0.03, 0.03, 0.03],
        [0.05, 0.45, 0.12],
        [0.1, 0.55, 0.8],
    ]
    private static let skins: [SIMD3<Float>] = [
        [0.62, 0.4, 0.28],
        [0.35, 0.2, 0.12],
        [0.8, 0.6, 0.48],
    ]

    static func sceneryMaterials(_ materials: MaterialFactory) -> [any Material] {
        Part.allCases.map { part in
            switch part {
            case .pavement: materials.paint([0.22, 0.22, 0.23], roughness: 0.9)
            case .concrete: materials.paint([0.42, 0.42, 0.44], roughness: 0.85)
            case .seats: materials.paint([0.55, 0.04, 0.05], roughness: 0.6)
            case .barrier: materials.paint([0.75, 0.75, 0.75], roughness: 0.7)
            case .stripe: materials.paint([0.7, 0.03, 0.03], roughness: 0.6)
            case .roof: materials.paint([0.8, 0.8, 0.82], metallic: 0.3, roughness: 0.5)
            case .glass: materials.paint([0.03, 0.06, 0.12], metallic: 0.7, roughness: 0.12)
            case .stoneA: materials.paint([0.5, 0.47, 0.42], roughness: 0.85)
            case .stoneB: materials.paint([0.3, 0.33, 0.38], roughness: 0.8)
            case .stoneC: materials.paint([0.62, 0.6, 0.58], roughness: 0.85)
            case .stoneD: materials.paint([0.16, 0.2, 0.27], metallic: 0.2, roughness: 0.6)
            }
        }
    }

    static func crowdMaterials(_ materials: MaterialFactory) -> [any Material] {
        (shirts + skins).map { materials.paint($0, roughness: 0.8) }
    }

    static func addScenery(to builder: inout MeshBuilder, firstPart: UInt32, length: Float, random: inout SeededRandom) {
        func part(_ part: Part) -> UInt32 { firstPart + part.rawValue }

        for side: Float in [-1, 1] {
            builder.addPlane(center: [side * 36.1, 0, 0], width: 57.8, depth: length, part: part(.pavement))
            builder.addBox(center: [side * 6.9, 0.5, 0], size: [0.25, 1, length], part: part(.barrier))
            builder.addBox(center: [side * 6.9, 1.06, 0], size: [0.28, 0.12, length], part: part(.stripe))

            for tier in 0..<tierCount {
                let x = standStart + Float(tier) * tierDepth
                let height = tierHeight(tier)
                builder.addBox(center: [side * (x + tierDepth / 2), height / 2, 0], size: [tierDepth, height, standLength], part: part(.concrete))
                builder.addBox(center: [side * (x + 0.3), height + 0.12, 0], size: [0.45, 0.24, standLength], part: part(.seats))
            }
            let back = standStart + Float(tierCount) * tierDepth
            builder.addBox(center: [side * (back + 0.15), 2.6, 0], size: [0.3, 5.2, standLength], part: part(.concrete))
            builder.addBox(center: [side * (back - 2.0), 5.2, 0], size: [4.6, 0.15, standLength + 1], part: part(.roof))

            addBuildings(to: &builder, side: side, near: 17...21, heights: 12...48, length: length, windows: true, random: &random, part: part)
            addBuildings(to: &builder, side: side, near: 40...46, heights: 28...85, length: length, windows: false, random: &random, part: part)
        }
    }

    // Two crowd meshes so the halves can bounce out of step, like a cheering stand.
    static func crowd(random: inout SeededRandom) -> [MeshBuilder] {
        var groups = [MeshBuilder(), MeshBuilder()]
        let skinStart = UInt32(shirts.count)

        for side: Float in [-1, 1] {
            for tier in 0..<tierCount {
                let seat = tierHeight(tier)
                let x = side * (standStart + Float(tier) * tierDepth + 0.8)
                for slot in stride(from: -standLength / 2 + 0.5, to: standLength / 2 - 0.3, by: 0.62) {
                    guard Float.random(in: 0..<1, using: &random) > 0.14 else { continue }
                    let group = Int.random(in: 0...1, using: &random)
                    let shirt = UInt32.random(in: 0..<UInt32(shirts.count), using: &random)
                    let skin = skinStart + UInt32.random(in: 0..<UInt32(skins.count), using: &random)
                    let z = slot + Float.random(in: -0.08...0.08, using: &random)
                    let tall = Float.random(in: 0.9...1.1, using: &random)
                    let shoulders = seat + 0.6 * tall

                    groups[group].addBox(center: [x, seat + 0.3 * tall, z], size: [0.3, 0.6 * tall, 0.42], part: shirt)
                    groups[group].addBox(center: [x, shoulders + 0.14, z], size: [0.24, 0.24, 0.24], part: skin)
                    if Float.random(in: 0..<1, using: &random) < 0.35 {
                        for arm: Float in [-0.24, 0.24] {
                            groups[group].addBox(center: [x, shoulders + 0.15, z + arm], size: [0.1, 0.42, 0.1], part: shirt)
                        }
                    }
                }
            }
        }
        return groups
    }

    private static func tierHeight(_ tier: Int) -> Float {
        0.5 + Float(tier) * 0.6
    }

    private static func addBuildings(
        to builder: inout MeshBuilder,
        side: Float,
        near: ClosedRange<Float>,
        heights: ClosedRange<Float>,
        length: Float,
        windows: Bool,
        random: inout SeededRandom,
        part: (Part) -> UInt32
    ) {
        let stones: [Part] = [.stoneA, .stoneB, .stoneC, .stoneD]
        let gap: Float = 1.5
        var z = -length / 2
        while z < length / 2 - 3 {
            let depth = min(Float.random(in: 7...13, using: &random), length / 2 - z)
            let inner = Float.random(in: near, using: &random)
            let width = Float.random(in: 8...16, using: &random)
            let height = Float.random(in: heights, using: &random)
            let body = depth - gap
            let centerX = side * (inner + width / 2)
            let centerZ = z + depth / 2
            let stone = stones.randomElement(using: &random) ?? .stoneA

            builder.addBox(center: [centerX, height / 2, centerZ], size: [width, height, body], part: part(stone))
            if Float.random(in: 0..<1, using: &random) < 0.4 {
                let cap = Float.random(in: 2...5, using: &random)
                builder.addBox(center: [centerX, height + cap / 2, centerZ], size: [width * 0.3, cap, body * 0.3], part: part(.concrete))
            }
            if windows {
                var y: Float = 3
                while y < height - 1.5 {
                    builder.addBox(center: [side * (inner - 0.06), y, centerZ], size: [0.14, 1.4, body * 0.86], part: part(.glass))
                    y += 3.4
                }
            }
            z += depth
        }
    }
}
