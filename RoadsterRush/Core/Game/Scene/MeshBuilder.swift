import Foundation
import RealityKit
import simd

// Accumulates triangles for one MeshResource; each face picks a material slot (`part`).
struct MeshBuilder {
    private var positions: [SIMD3<Float>] = []
    private var normals: [SIMD3<Float>] = []
    private var indices: [UInt32] = []
    private var faceParts: [UInt32] = []

    mutating func addTriangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, outward: SIMD3<Float>, part: UInt32) {
        var b = b
        var c = c
        var normal = simd_cross(b - a, c - a)
        if simd_dot(normal, outward) < 0 {
            swap(&b, &c)
            normal = -normal
        }
        let length = simd_length(normal)
        guard length > 0 else { return }
        normal /= length
        append([a, b, c], normals: [normal, normal, normal], part: part)
    }

    mutating func addQuad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>, outward: SIMD3<Float>, part: UInt32) {
        addTriangle(a, b, c, outward: outward, part: part)
        addTriangle(a, c, d, outward: outward, part: part)
    }

    mutating func addPlane(center: SIMD3<Float>, width: Float, depth: Float, part: UInt32) {
        let w = width / 2
        let d = depth / 2
        addQuad(
            center + [-w, 0, -d], center + [-w, 0, d], center + [w, 0, d], center + [w, 0, -d],
            outward: [0, 1, 0], part: part
        )
    }

    mutating func addBox(center: SIMD3<Float>, size: SIMD3<Float>, rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), part: UInt32) {
        let h = size / 2
        func p(_ x: Float, _ y: Float, _ z: Float) -> SIMD3<Float> { center + rotation.act(SIMD3(x * h.x, y * h.y, z * h.z)) }
        func n(_ x: Float, _ y: Float, _ z: Float) -> SIMD3<Float> { rotation.act(SIMD3(x, y, z)) }
        addQuad(p(1, -1, -1), p(1, 1, -1), p(1, 1, 1), p(1, -1, 1), outward: n(1, 0, 0), part: part)
        addQuad(p(-1, -1, -1), p(-1, 1, -1), p(-1, 1, 1), p(-1, -1, 1), outward: n(-1, 0, 0), part: part)
        addQuad(p(-1, 1, -1), p(1, 1, -1), p(1, 1, 1), p(-1, 1, 1), outward: n(0, 1, 0), part: part)
        addQuad(p(-1, -1, -1), p(1, -1, -1), p(1, -1, 1), p(-1, -1, 1), outward: n(0, -1, 0), part: part)
        addQuad(p(-1, -1, 1), p(1, -1, 1), p(1, 1, 1), p(-1, 1, 1), outward: n(0, 0, 1), part: part)
        addQuad(p(-1, -1, -1), p(1, -1, -1), p(1, 1, -1), p(-1, 1, -1), outward: n(0, 0, -1), part: part)
    }

    // A capped cone or cylinder along local y, centered on `center`.
    mutating func addFrustum(
        center: SIMD3<Float>,
        bottomRadius: Float,
        topRadius: Float,
        height: Float,
        segments: Int,
        rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
        part: UInt32
    ) {
        let half = height / 2
        let slope = (bottomRadius - topRadius) / height
        func place(_ v: SIMD3<Float>) -> SIMD3<Float> { center + rotation.act(v) }
        for i in 0..<segments {
            let a0 = Float(i) / Float(segments) * 2 * .pi
            let a1 = Float(i + 1) / Float(segments) * 2 * .pi
            let d0 = SIMD3<Float>(cos(a0), 0, sin(a0))
            let d1 = SIMD3<Float>(cos(a1), 0, sin(a1))
            let b0 = d0 * bottomRadius + [0, -half, 0]
            let b1 = d1 * bottomRadius + [0, -half, 0]
            let t0 = d0 * topRadius + [0, half, 0]
            let t1 = d1 * topRadius + [0, half, 0]
            let n0 = rotation.act(simd_normalize(d0 + [0, slope, 0]))
            let n1 = rotation.act(simd_normalize(d1 + [0, slope, 0]))
            let outward = rotation.act(d0 + d1)
            appendSmoothTriangle([place(b0), place(b1), place(t1)], normals: [n0, n1, n1], outward: outward, part: part)
            appendSmoothTriangle([place(b0), place(t1), place(t0)], normals: [n0, n1, n0], outward: outward, part: part)
            if bottomRadius > 0 {
                addTriangle(place([0, -half, 0]), place(b0), place(b1), outward: rotation.act([0, -1, 0]), part: part)
            }
            if topRadius > 0 {
                addTriangle(place([0, half, 0]), place(t0), place(t1), outward: rotation.act([0, 1, 0]), part: part)
            }
        }
    }

    // Flat ring lying on y = 0, facing up.
    mutating func addAnnulus(innerRadius: Float, outerRadius: Float, segments: Int, part: UInt32) {
        for i in 0..<segments {
            let a0 = Float(i) / Float(segments) * 2 * .pi
            let a1 = Float(i + 1) / Float(segments) * 2 * .pi
            let d0 = SIMD3<Float>(cos(a0), 0, sin(a0))
            let d1 = SIMD3<Float>(cos(a1), 0, sin(a1))
            addQuad(d0 * innerRadius, d0 * outerRadius, d1 * outerRadius, d1 * innerRadius, outward: [0, 1, 0], part: part)
        }
    }

    func makeMesh(name: String) throws -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        descriptor.materials = .perFace(faceParts)
        return try MeshResource.generate(from: [descriptor])
    }

    private mutating func appendSmoothTriangle(_ points: [SIMD3<Float>], normals: [SIMD3<Float>], outward: SIMD3<Float>, part: UInt32) {
        let face = simd_cross(points[1] - points[0], points[2] - points[0])
        guard simd_length(face) > 0 else { return }
        if simd_dot(face, outward) < 0 {
            append([points[0], points[2], points[1]], normals: [normals[0], normals[2], normals[1]], part: part)
        } else {
            append(points, normals: normals, part: part)
        }
    }

    private mutating func append(_ points: [SIMD3<Float>], normals: [SIMD3<Float>], part: UInt32) {
        let base = UInt32(positions.count)
        positions.append(contentsOf: points)
        self.normals.append(contentsOf: normals)
        indices.append(contentsOf: [base, base + 1, base + 2])
        faceParts.append(part)
    }
}
