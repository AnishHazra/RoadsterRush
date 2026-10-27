import RealityKit

// Ring under the car while airborne: green over road, red over cars.
final class LandingRing {
    let entity: ModelEntity
    private let safe: ModelComponent
    private let danger: ModelComponent
    private var showingDanger = false

    init(materials: MaterialFactory) throws {
        var builder = MeshBuilder()
        builder.addAnnulus(innerRadius: 0.9, outerRadius: 1.15, segments: 40, part: 0)
        let mesh = try builder.makeMesh(name: "landingRing")
        safe = ModelComponent(mesh: mesh, materials: [materials.unlit([0.2, 1, 0.45])])
        danger = ModelComponent(mesh: mesh, materials: [materials.unlit([1, 0.15, 0.15])])
        entity = ModelEntity()
        entity.model = safe
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        entity.isEnabled = false
    }

    func place(x: Double, z: Double, top: Double, visible: Bool) {
        entity.isEnabled = visible
        guard visible else { return }
        let overCars = top > 0
        if overCars != showingDanger {
            showingDanger = overCars
            entity.model = overCars ? danger : safe
        }
        entity.position = GameSpace.world(x, top + 0.03, z)
    }
}
