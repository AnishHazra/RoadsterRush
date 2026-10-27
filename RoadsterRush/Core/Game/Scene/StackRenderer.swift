import RealityKit
import simd

// Mirrors GameModel.blocks into entities, reusing pooled car entities.
final class StackRenderer {
    let root = Entity()
    private let fleet: FleetMeshes
    private var active: [Int: [ModelEntity]] = [:]
    private var pool: [ModelEntity] = []
    private var syncedVersion = -1
    private static let sideways = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
    private static let sidewaysFlipped = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])

    init(fleet: FleetMeshes) {
        self.fleet = fleet
    }

    func sync(_ blocks: [Block], version: Int) {
        guard version != syncedVersion else { return }
        syncedVersion = version

        let liveIDs = Set(blocks.map(\.id))
        for id in Array(active.keys) where !liveIDs.contains(id) {
            for car in active.removeValue(forKey: id) ?? [] {
                car.isEnabled = false
                pool.append(car)
            }
        }
        for block in blocks where active[block.id] == nil {
            active[block.id] = block.cars.map(makeCar)
        }
    }

    private func makeCar(_ car: ParkedCar) -> ModelEntity {
        let entity: ModelEntity
        if let reused = pool.popLast() {
            entity = reused
        } else {
            entity = ModelEntity()
            root.addChild(entity)
        }
        entity.model = fleet.model(car.kind, color: car.color)
        entity.position = GameSpace.world(car.x, car.y, car.z)
        entity.orientation = car.flipped ? Self.sideways : Self.sidewaysFlipped
        entity.scale = SIMD3(repeating: Float(car.scale))
        entity.isEnabled = true
        return entity
    }
}
