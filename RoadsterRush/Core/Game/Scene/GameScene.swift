import Foundation
import RealityKit
import SwiftUI
import simd

// Owns the RealityKit world and mirrors GameModel into it every frame.
final class GameScene {
    let root = Entity()
    private(set) var renderedFrames = 0

    private let model: GameModel
    private let sky: EnvironmentResource?
    private let camera = PerspectiveCamera()
    private let sun = DirectionalLight()
    private let road: Road
    private let player: PlayerCar
    private let smoke = Smoke()
    private let ring: LandingRing
    private let stacks: StackRenderer
    private var updates: EventSubscription?
    private var puffClock: Float = 0
    private var excitement: Float = 0.25
    private var lastZ = 0.0
    private static let sunDirection = simd_normalize(SIMD3<Float>(-0.35, -1, -0.45))

    init(model: GameModel, assets: GameAssets) throws {
        self.model = model
        sky = assets.sky
        road = try Road(materials: assets.materials)
        player = try PlayerCar(model: assets.roadster, materials: assets.materials)
        ring = try LandingRing(materials: assets.materials)
        stacks = StackRenderer(fleet: assets.fleet)

        camera.camera.fieldOfViewInDegrees = 58
        camera.camera.near = 0.1
        camera.camera.far = 400

        sun.light.intensity = 2800
        sun.shadow = DirectionalLightComponent.Shadow(shadowProjection: .automatic(maximumDistance: 70), depthBias: 1)
        sun.orientation = GameSpace.lookRotation(from: .zero, to: Self.sunDirection)

        for child in [camera, sun, road.root, stacks.root, player.entity, smoke.root, ring.entity] as [Entity] {
            root.addChild(child)
        }
        update(0)
    }

    func install(in content: inout RealityViewCameraContent) {
        content.camera = .virtual
        if let sky { content.environment = .skybox(sky) }
        content.add(root)
        updates?.cancel()
        updates = content.subscribe(to: SceneEvents.Update.self, on: nil, componentType: nil) { [weak self] event in
            self?.update(event.deltaTime)
        }
    }

    private func update(_ dt: TimeInterval) {
        renderedFrames += 1
        model.tick(dt)
        guard !model.isPaused else { return }
        let step = Float(min(dt, 1.0 / 20))

        if model.z < lastZ - 1 {
            road.reset()
            smoke.clear()
        }
        lastZ = model.z
        road.follow(model.z)
        let hype: Float = model.state == .playing && model.airborne ? 1 : 0.25
        excitement += (hype - excitement) * min(1, step * 3)
        road.cheer(time: Float(model.time), excitement: excitement)
        stacks.sync(model.blocks, version: model.blocksVersion)

        player.thrusters.set(power: Float(model.flame), push: Float(model.push), torque: Float(model.torque), time: Float(model.time))
        smoke.tick(step)
        player.place(x: model.x, y: model.y, z: model.z, roll: model.bodyRoll, pitch: model.bodyPitch)
        puff(step)
        ring.place(x: model.x, z: model.z, top: model.surfaceAt(model.x, model.z), visible: model.airborne && model.state == .playing)

        let eye = GameSpace.world(model.cameraPosition)
        camera.position = eye
        camera.orientation = GameSpace.lookRotation(from: eye, to: GameSpace.world(model.cameraTarget))
    }

    private func puff(_ dt: Float) {
        guard model.state == .playing else { return }
        let jets = player.thrusters.jets
        guard jets.contains(where: { $0.power >= 0.1 }) else {
            puffClock = 0
            return
        }
        let rotation = player.rotation
        let carry = SIMD3<Float>(Float(model.vx) * 0.5, Float(model.vy) * 0.3, -Float(model.speed) * 0.25)
        puffClock += dt * 28
        while puffClock >= 1 {
            puffClock -= 1
            for jet in jets where jet.power >= 0.1 {
                let out = rotation.act(jet.direction)
                let tip = jet.origin + jet.direction * (0.5 + jet.power * 0.7)
                let position = player.entity.position + rotation.act(tip)
                smoke.emit(at: position, velocity: out * (5 + jet.power * 6) + carry, size: 0.3 + jet.power * 0.3)
            }
        }
    }
}
