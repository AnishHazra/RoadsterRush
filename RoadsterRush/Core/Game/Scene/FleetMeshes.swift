import Foundation
import os
import RealityKit
import simd

// Parked Teslas from Resources/Fleet/*.bin (built by build_fleet.py), one ModelComponent per paint.
final class FleetMeshes {
    enum LoadError: Error {
        case missingFile(String)
        case truncated(String)
    }

    private static let paints: [SIMD3<Float>] = [
        [0.9, 0.9, 0.92],
        [0.03, 0.03, 0.035],
        [0.62, 0.02, 0.03],
        [0.04, 0.14, 0.45],
        [0.28, 0.29, 0.31],
        [0.62, 0.63, 0.65],
    ]

    private var models: [[ModelComponent]] = []
    private let logger = Logger(subsystem: "RoadsterRush", category: "Fleet")

    init(materials: MaterialFactory) {
        let paintMaterials = Self.paints.map { materials.paint($0, metallic: 0.35, roughness: 0.28) }
        let dark = materials.paint([0.03, 0.03, 0.035], metallic: 0.35, roughness: 0.2)
        let steel = materials.paint([0.62, 0.63, 0.65], metallic: 1, roughness: 0.38)

        for kind in CarKind.allCases {
            let mesh = loadMesh(kind)
            if kind == .cybertruck {
                let model = ModelComponent(mesh: mesh, materials: [steel, dark])
                models.append(Array(repeating: model, count: CarKind.colorCount))
            } else {
                models.append(paintMaterials.map { ModelComponent(mesh: mesh, materials: [$0, dark]) })
            }
        }
    }

    func model(_ kind: CarKind, color: Int) -> ModelComponent {
        models[kind.rawValue][color % CarKind.colorCount]
    }

    private func loadMesh(_ kind: CarKind) -> MeshResource {
        do {
            return try Self.readBin(kind)
        } catch {
            logger.error("Using box for \(kind.fileName): \(String(describing: error))")
            var builder = MeshBuilder()
            let size = SIMD3<Float>(Float(kind.width), Float(kind.height), Float(kind.length))
            builder.addBox(center: [0, size.y * 0.35, 0], size: [size.x, size.y * 0.7, size.z], part: 0)
            builder.addBox(center: [0, size.y * 0.85, 0.1], size: [size.x * 0.85, size.y * 0.3, size.z * 0.55], part: 1)
            return (try? builder.makeMesh(name: kind.fileName)) ?? MeshResource.generateBox(size: size)
        }
    }

    // Layout: length, width, height (f32), vertex count, index count (u32), positions, normals, colors, indices.
    private static func readBin(_ kind: CarKind) throws -> MeshResource {
        guard let url = Bundle.main.url(forResource: kind.fileName, withExtension: "bin") else {
            throw LoadError.missingFile(kind.fileName)
        }
        let data = try Data(contentsOf: url)
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        var parts: [UInt32] = []

        try data.withUnsafeBytes { raw in
            guard raw.count >= 20 else { throw LoadError.truncated(kind.fileName) }
            let vertexCount = Int(raw.loadUnaligned(fromByteOffset: 12, as: UInt32.self))
            let indexCount = Int(raw.loadUnaligned(fromByteOffset: 16, as: UInt32.self))
            let positionStart = 20
            let normalStart = positionStart + vertexCount * 12
            let colorStart = normalStart + vertexCount * 12
            let indexStart = colorStart + vertexCount * 16
            guard indexStart + indexCount * 4 <= raw.count else { throw LoadError.truncated(kind.fileName) }

            func vector(_ start: Int, _ i: Int) -> SIMD3<Float> {
                let base = start + i * 12
                return SIMD3(
                    raw.loadUnaligned(fromByteOffset: base, as: Float.self),
                    raw.loadUnaligned(fromByteOffset: base + 4, as: Float.self),
                    -raw.loadUnaligned(fromByteOffset: base + 8, as: Float.self)
                )
            }
            func shade(_ i: UInt32) -> Float {
                raw.loadUnaligned(fromByteOffset: colorStart + Int(i) * 16, as: Float.self)
            }

            positions.reserveCapacity(vertexCount)
            normals.reserveCapacity(vertexCount)
            for i in 0..<vertexCount {
                positions.append(vector(positionStart, i))
                normals.append(vector(normalStart, i))
            }
            indices.reserveCapacity(indexCount)
            parts.reserveCapacity(indexCount / 3)
            for t in stride(from: 0, to: indexCount - 2, by: 3) {
                let a = raw.loadUnaligned(fromByteOffset: indexStart + t * 4, as: UInt32.self)
                let b = raw.loadUnaligned(fromByteOffset: indexStart + (t + 1) * 4, as: UInt32.self)
                let c = raw.loadUnaligned(fromByteOffset: indexStart + (t + 2) * 4, as: UInt32.self)
                guard Int(max(a, b, c)) < vertexCount else { throw LoadError.truncated(kind.fileName) }
                // Mirroring z flips the winding, so swap two corners to keep faces outward.
                indices.append(contentsOf: [a, c, b])
                parts.append((shade(a) + shade(b) + shade(c)) / 3 < 0.5 ? 1 : 0)
            }
        }

        var descriptor = MeshDescriptor(name: kind.fileName)
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        descriptor.materials = .perFace(parts)
        return try MeshResource.generate(from: [descriptor])
    }
}
