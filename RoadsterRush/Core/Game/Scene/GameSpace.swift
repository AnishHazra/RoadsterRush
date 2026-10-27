import simd

// The Flutter game is left-handed (+z forward, +x screen-right). RealityKit is right-handed,
// so game z is mirrored: world = (x, y, -z). Roll is unchanged; pitch and yaw flip sign.
enum GameSpace {
    static func world(_ x: Double, _ y: Double, _ z: Double) -> SIMD3<Float> {
        SIMD3<Float>(Float(x), Float(y), Float(-z))
    }

    static func world(_ point: SIMD3<Double>) -> SIMD3<Float> {
        world(point.x, point.y, point.z)
    }

    // Orientation whose -Z axis points from `eye` toward `target`, like a camera or light.
    static func lookRotation(from eye: SIMD3<Float>, to target: SIMD3<Float>) -> simd_quatf {
        let back = simd_normalize(eye - target)
        let right = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), back))
        let up = simd_cross(back, right)
        return simd_quatf(simd_float3x3(columns: (right, up, back)))
    }
}
