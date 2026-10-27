struct Pile {
    let minX: Double
    let maxX: Double
    let top: Double
}

struct ParkedCar {
    let kind: CarKind
    let color: Int
    let x: Double
    let y: Double
    let z: Double
    let flipped: Bool
    let scale: Double
}

// A row of stacked parked cars across the road. Positions are in game space (+z is forward).
struct Block {
    let id: Int
    let start: Double
    let end: Double
    let piles: [Pile]
    let cars: [ParkedCar]
}
