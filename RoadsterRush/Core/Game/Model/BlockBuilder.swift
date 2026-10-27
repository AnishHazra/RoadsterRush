struct BlockBuilder {
    static let halfRoad = RoadLayout.halfWidth - 0.05

    private var nextID = 0

    mutating func build(start: Double, level: Int) -> Block {
        let halfRoad = Self.halfRoad
        let rows = 1 + Int.random(in: 0..<min(level, 3))
        let maxLayers = min(1 + level / 2, 4)
        let columns = [-halfRoad / 2, halfRoad / 2]
        let layers = columns.map { _ in 1 + Int.random(in: 0..<maxLayers) }
        var tops = [0.0, 0.0]
        var cars: [ParkedCar] = []

        var z = start
        for _ in 0..<rows {
            var rowDepth = 0.0
            for c in columns.indices {
                var y = 0.0
                for _ in 0..<layers[c] {
                    let kind = CarKind.allCases.randomElement() ?? .model3
                    let scale = min(1.0, (halfRoad - 0.1) / kind.length)
                    cars.append(
                        ParkedCar(
                            kind: kind,
                            color: Int.random(in: 0..<CarKind.colorCount),
                            x: columns[c],
                            y: y,
                            z: z + kind.width * scale / 2,
                            flipped: Bool.random(),
                            scale: scale
                        )
                    )
                    y += kind.height * scale * 0.94
                    rowDepth = max(rowDepth, kind.width * scale)
                }
                tops[c] = max(tops[c], y + 0.06)
            }
            z += rowDepth + 0.15
        }

        nextID += 1
        let piles = [Pile(minX: -halfRoad, maxX: 0, top: tops[0]), Pile(minX: 0, maxX: halfRoad, top: tops[1])]
        return Block(id: nextID, start: start, end: z, piles: piles, cars: cars)
    }
}
