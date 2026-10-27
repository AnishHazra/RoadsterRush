// Parked Tesla models; sizes match the headers of Resources/Fleet/*.bin.
enum CarKind: Int, CaseIterable {
    case model3
    case modelS
    case modelY
    case modelX
    case cybertruck

    static let colorCount = 6

    var fileName: String {
        switch self {
        case .model3: "model_3"
        case .modelS: "model_s"
        case .modelY: "model_y"
        case .modelX: "model_x"
        case .cybertruck: "cybertruck"
        }
    }

    var length: Double {
        switch self {
        case .model3: 4.72
        case .modelS: 4.98
        case .modelY: 4.75
        case .modelX: 5.05
        case .cybertruck: 5.68
        }
    }

    var width: Double {
        switch self {
        case .model3: 1.85
        case .modelS: 1.96
        case .modelY: 1.92
        case .modelX: 2.0
        case .cybertruck: 2.2
        }
    }

    var height: Double {
        switch self {
        case .model3: 1.44
        case .modelS: 1.43
        case .modelY: 1.62
        case .modelX: 1.68
        case .cybertruck: 1.79
        }
    }
}
