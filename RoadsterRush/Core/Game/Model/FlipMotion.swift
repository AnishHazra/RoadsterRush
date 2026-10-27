import Foundation

struct FlipPose: Equatable {
    let roll: Double
    let torque: Double
}

// Barrel roll as a reaction-control burn: spin up, coast, then brake after exactly one turn.
enum FlipMotion {
    static let spinUp = 0.18
    static let coast = 0.36
    static let duration = spinUp * 2 + coast
    static let spinRate = 2 * Double.pi / (spinUp * spinUp + spinUp * coast)
    static let kickPower = 1.4

    static func at(_ t: Double, turn: Double) -> FlipPose {
        if t < 0 || t >= duration { return FlipPose(roll: 0, torque: 0) }
        if t < spinUp { return FlipPose(roll: turn * 0.5 * spinRate * t * t, torque: turn) }
        if t < spinUp + coast {
            return FlipPose(roll: turn * (0.5 * spinRate * spinUp * spinUp + spinRate * spinUp * (t - spinUp)), torque: 0)
        }
        let left = duration - t
        return FlipPose(roll: turn * (2 * Double.pi - 0.5 * spinRate * left * left), torque: -turn)
    }

    static func kick(_ t: Double, direction: Double) -> Double {
        t >= 0 && t < spinUp ? direction * kickPower : 0
    }
}
