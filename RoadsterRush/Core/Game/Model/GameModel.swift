import Foundation
import Observation

// Port of roadster_game.dart. Everything here is in game space: +x right, +y up, +z forward.
@Observable
final class GameModel {
    static let gravity = 16.0
    static let thrustPower = 34.0
    static let maxRise = 9.0
    static let drain = 0.36
    static let refill = 0.32
    static let halfWidth = 1.0
    static let halfLength = 2.25
    static let sideLimit = RoadLayout.halfWidth - halfWidth - 0.1
    static let sideSpeed = 7.5
    static let sideJetPower = 55.0
    static let flipPoints = 25
    static let levelLength = 500.0

    private(set) var state: GameState = .ready
    private(set) var isPaused = false
    private(set) var score = 0
    private(set) var level = 1
    private(set) var air = 1.0
    private(set) var flips = 0
    private(set) var distance = 0
    private(set) var metersToNextLevel = 500
    private(set) var flying = false
    private(set) var flipping = false
    private(set) var isAirborne = false
    private(set) var landingOnCars = false
    private(set) var stackAhead: Int?
    private(set) var best = 0
    private(set) var isNewBest = false
    private(set) var stick: SIMD2<Double> = .zero
    private(set) var demo = false

    @ObservationIgnored let sounds: SoundService
    @ObservationIgnored let haptics: HapticsService
    @ObservationIgnored private(set) var blocks: [Block] = []
    @ObservationIgnored private(set) var blocksVersion = 0
    @ObservationIgnored private(set) var x = 0.0
    @ObservationIgnored private(set) var y = 0.0
    @ObservationIgnored private(set) var z = 0.0
    @ObservationIgnored private(set) var vx = 0.0
    @ObservationIgnored private(set) var vy = 0.0
    @ObservationIgnored private(set) var speed = 0.0
    @ObservationIgnored private(set) var push = 0.0
    @ObservationIgnored private(set) var torque = 0.0
    @ObservationIgnored private(set) var flame = 0.0
    @ObservationIgnored private(set) var bodyRoll = 0.0
    @ObservationIgnored private(set) var bodyPitch = 0.0
    @ObservationIgnored private(set) var time = 0.0
    @ObservationIgnored private(set) var cameraPosition = SIMD3<Double>(0, 4.5, -11)
    @ObservationIgnored private(set) var cameraTarget = SIMD3<Double>(0, 1.4, 10)

    @ObservationIgnored private var builder = BlockBuilder()
    @ObservationIgnored private var airLevel = 1.0
    @ObservationIgnored private var flip = -1.0
    @ObservationIgnored private var flipDir = 1.0
    @ObservationIgnored private var roll = 0.0
    @ObservationIgnored private var bonus = 0
    @ObservationIgnored private var nextBlock = 70.0
    @ObservationIgnored private var shake = 0.0
    @ObservationIgnored private var thrusting = false
    @ObservationIgnored private var demoTime = 0.0
    @ObservationIgnored private var lastFlip = 0.0
    @ObservationIgnored private var bestBeforeRun = 0

    var airborne: Bool { y > 0.001 || vy > 0 }
    var isLive: Bool { state == .playing && !isPaused }

    init(sounds: SoundService, haptics: HapticsService) {
        self.sounds = sounds
        self.haptics = haptics
    }

    func setBest(_ value: Int) {
        best = value
    }

    func enableDemo() {
        demo = true
    }

    func setStick(_ value: SIMD2<Double>) {
        stick = value
    }

    func thrust(_ on: Bool) {
        if on && state == .ready { start() }
        let wasThrusting = thrusting
        thrusting = on && isLive
        if thrusting && !wasThrusting { haptics.tick() }
    }

    func flipCar() {
        guard isLive, flip < 0 else { return }
        flipDir = abs(stick.x) > 0.2 ? (stick.x > 0 ? 1 : -1) : (x > 0 ? -1 : 1)
        flip = 0
        if !airborne { vy = 8 }
        sounds.flip()
    }

    func start() {
        resetRun()
        bestBeforeRun = best
        state = .playing
    }

    func pause() {
        guard state == .playing, !isPaused else { return }
        isPaused = true
        thrusting = false
        flying = false
        sounds.loops(thrust: 0, side: 0)
    }

    func resume() {
        isPaused = false
    }

    func returnToTitle() {
        resetRun()
        state = .ready
    }

    func tick(_ rawDt: Double) {
        guard !isPaused else { return }
        let dt = min(rawDt, 1.0 / 20)
        time += dt
        if demo { autopilot(dt) }
        switch state {
        case .ready:
            spawn()
        case .playing:
            fly(dt)
            spawn()
            checkCrash()
        case .crashed:
            break
        }
        shake = max(0, shake - dt * 2)
        flame += ((thrusting ? 1.0 : (airborne ? 0.12 : 0.0)) - flame) * min(1, dt * 12)
        let live = state == .playing
        sounds.loops(thrust: live ? flame : 0, side: live ? max(abs(push), abs(torque)) : 0)
        placeBody()
        placeCamera(dt)
        publish()
    }

    func surfaceAt(_ x: Double, _ z: Double) -> Double {
        var top = 0.0
        for block in blocks {
            if z + Self.halfLength < block.start || z - Self.halfLength > block.end { continue }
            for pile in block.piles {
                if x + Self.halfWidth < pile.minX || x - Self.halfWidth > pile.maxX { continue }
                top = max(top, pile.top)
            }
        }
        return top
    }

    private func resetRun() {
        blocks.removeAll()
        blocksVersion += 1
        x = 0
        vx = 0
        push = 0
        flip = -1
        roll = 0
        torque = 0
        bonus = 0
        y = 0
        vy = 0
        z = 0
        time = 0
        nextBlock = 70
        flame = 0
        shake = 0
        thrusting = false
        demoTime = 0
        lastFlip = 0
        airLevel = 1
        isPaused = false
        isNewBest = false
        flips = 0
        score = 0
        level = 1
    }

    private func fly(_ dt: Double) {
        level = 1 + Int((z / Self.levelLength).rounded(.down))
        speed = min(18 + Double(level - 1) * 1.6, 34)

        let wasAirborne = airborne
        flipStep(dt)
        let across = cos(roll)
        let tilt = sin(roll)
        if thrusting && airLevel > 0 {
            vy += Self.thrustPower * across * dt
            vx -= Self.thrustPower * tilt * dt
            airLevel = max(0, airLevel - Self.drain * dt)
        }
        vy = min(vy - Self.gravity * dt, Self.maxRise)
        y += vy * dt
        if y <= 0 {
            if wasAirborne && vy < -6 {
                shake = 0.5
                haptics.hardLanding()
            }
            if wasAirborne { sounds.land() }
            y = 0
            vy = 0
        }
        if !airborne && !thrusting {
            airLevel = min(1, airLevel + Self.refill * dt)
        }

        let reach = airborne ? 1 - stick.y * 0.35 : 1.0
        z += speed * reach * dt
        if flip < 0 {
            let target = stick.x * Self.sideSpeed
            let grip = airborne ? 3.5 : 14.0
            let change = (target - vx) * min(1, dt * grip)
            vx += change
            let steer = airborne ? min(max(change / dt / 25, -1), 1) : 0
            push += (steer - push) * min(1, dt * 10)
        } else {
            let kick = FlipMotion.kick(flip, direction: flipDir)
            push += (kick - push) * min(1, dt * 30)
            vx += push / FlipMotion.kickPower * Self.sideJetPower * across * dt
            vy += push / FlipMotion.kickPower * Self.sideJetPower * tilt * dt
            vx *= 1 - min(1, dt * 0.4)
        }
        x += vx * dt
        if abs(x) > Self.sideLimit {
            x = min(max(x, -Self.sideLimit), Self.sideLimit)
            vx = 0
        }

        score = Int((z / 5).rounded(.down)) + bonus
    }

    private func spawn() {
        while nextBlock < z + 190 {
            let block = builder.build(start: nextBlock, level: level)
            blocks.append(block)
            blocksVersion += 1
            let gap = max(24.0, 46 - Double(level) * 2.5)
            nextBlock = block.end + gap + Double.random(in: 0..<1) * 12
        }
        while let first = blocks.first, first.end < z - 20 {
            blocks.removeFirst()
            blocksVersion += 1
        }
    }

    private func checkCrash() {
        guard y < surfaceAt(x, z) - 0.05 else { return }
        state = .crashed
        thrusting = false
        shake = 1
        flip = -1
        roll = 0
        torque = 0
        push = 0
        sounds.crash()
        haptics.crash()
        best = max(best, score)
        isNewBest = score > bestBeforeRun
    }

    private func flipStep(_ dt: Double) {
        guard flip >= 0 else { return }
        flip += dt
        if flip < FlipMotion.duration {
            let pose = FlipMotion.at(flip, turn: -flipDir)
            roll = pose.roll
            torque = pose.torque
        } else {
            flip = -1
            roll = 0
            torque = 0
            if airborne {
                bonus += Self.flipPoints
                flips += 1
                sounds.bonus()
                haptics.success()
            }
        }
    }

    private func placeBody() {
        let bank = flip < 0 ? -min(max(vx / Self.sideSpeed, -1), 1) * 0.22 : 0
        bodyRoll = bank + roll
        bodyPitch = airborne ? -vy * 0.02 : 0
    }

    private func placeCamera(_ dt: Double) {
        let follow = min(1.0, dt * 5)
        if state == .ready && !demo {
            // Slow fly-by of the stacks behind the title screen.
            let drift = SIMD3<Double>(sin(time * 0.2) * 2.5, 6 + sin(time * 0.13), 28 + sin(time * 0.1) * 10)
            cameraPosition += (drift - cameraPosition) * follow * 0.3
            cameraTarget = SIMD3<Double>(sin(time * 0.15) * 1.5, 1.5, cameraPosition.z + 30)
            return
        }
        let shakeX = sin(time * 47) * shake * 0.12
        let shakeY = cos(time * 53) * shake * 0.1
        let clearance = max(surfaceAt(x * 0.5, z - 11), surfaceAt(x * 0.5, z - 6)) + 2.5
        let height = max(4.5 + y * 0.75, clearance)
        let desired = SIMD3<Double>(x * 0.5 + shakeX, height + shakeY, z - 11)
        let eased = cameraPosition + (desired - cameraPosition) * follow
        cameraPosition = SIMD3<Double>(eased.x, eased.y, desired.z)
        cameraTarget = SIMD3<Double>(x * 0.7, 1.4 + y * 0.7, z + 10)
    }

    private func publish() {
        let shownAir = (airLevel * 200).rounded() / 200
        if air != shownAir { air = shownAir }
        if flying != thrusting { flying = thrusting }
        if flipping != (flip >= 0) { flipping = flip >= 0 }
        if isAirborne != airborne { isAirborne = airborne }
        let onCars = airborne && surfaceAt(x, z) > 0
        if landingOnCars != onCars { landingOnCars = onCars }
        let meters = Int(z)
        if distance != meters { distance = meters }
        let left = Int(Self.levelLength) - meters % Int(Self.levelLength)
        if metersToNextLevel != left { metersToNextLevel = left }
        let ahead = nextStackDistance()
        if stackAhead != ahead { stackAhead = ahead }
    }

    private func nextStackDistance() -> Int? {
        guard state == .playing, !airborne else { return nil }
        for block in blocks where block.end > z - Self.halfLength {
            let gap = block.start - (z + Self.halfLength)
            return gap < 75 ? max(0, Int(gap)) : nil
        }
        return nil
    }

    private func willHit(_ lookahead: Double) -> Bool {
        var y = self.y
        var vy = self.vy
        var z = self.z
        let step = 1.0 / 30
        var t = 0.0
        while t < lookahead {
            vy -= Self.gravity * step
            y += vy * step
            z += speed * step
            if y < surfaceAt(x, z) + 0.9 { return true }
            if y <= 0 { return false }
            t += step
        }
        return false
    }

    private func autopilot(_ dt: Double) {
        if state == .ready {
            demoTime += dt
            if demoTime > 2.2 { start() }
            return
        }
        guard state == .playing else { return }
        demoTime += dt

        var aim = 0.0
        if let next = blocks.first(where: { $0.end > z - Self.halfLength }) {
            let low = next.piles[0].top <= next.piles[1].top ? next.piles[0] : next.piles[1]
            aim = (low.minX + low.maxX) / 2
        }
        aim += sin(demoTime * 1.3) * 0.6
        let steer = min(max((aim - x) * 0.6, -1), 1)

        let ending = demoTime > 27
        let danger = !ending && willHit(1.4)
        let high = y - surfaceAt(x, z)
        let canFlip = !ending && airborne && flip < 0 && high > 2.2 && vy > -1 && demoTime - lastFlip > 2.6 && !willHit(1.1)

        setStick(SIMD2(steer, 0))
        if canFlip {
            lastFlip = demoTime
            setStick(SIMD2(x > 0 ? -1 : 1, 0))
            flipCar()
        }
        let wantThrust = flip < 0 && danger && airLevel > 0
        if wantThrust != thrusting { thrust(wantThrust) }
    }
}
