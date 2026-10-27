import Foundation
import Observation
import os
import RealityKit

@Observable
final class AssetLoader {
    enum Stage {
        case roadster
        case fleet
        case gpu
        case done

        var status: String {
            switch self {
            case .roadster: "LOADING ROADSTER.GLB"
            case .fleet: "LOADING TESLA FLEET"
            case .gpu: "WARMING UP GPU"
            case .done: "READY"
            }
        }
    }

    private(set) var stage: Stage = .roadster
    private(set) var progress = 0.0
    private(set) var scene: GameScene?
    private(set) var failure: String?

    private let logger = Logger(subsystem: "RoadsterRush", category: "Loading")

    func load(game: GameModel) async {
        guard scene == nil, failure == nil else { return }

        stage = .roadster
        progress = 0.05
        let roadster = await loadRoadster()
        progress = 0.4
        guard await pause() else { return }

        stage = .fleet
        let materials = MaterialFactory()
        let fleet = FleetMeshes(materials: materials)
        progress = 0.6
        await game.sounds.load()
        game.haptics.prepare()
        progress = 0.72
        guard await pause() else { return }

        stage = .gpu
        let sky = await SkyEnvironment.make()
        progress = 0.82
        do {
            scene = try GameScene(model: game, assets: GameAssets(roadster: roadster, materials: materials, fleet: fleet, sky: sky))
        } catch {
            logger.error("Scene build failed: \(error.localizedDescription)")
            failure = "Could not build the 3D scene."
            return
        }
        progress = 0.9
        await waitForFirstFrames()
        progress = 1
        stage = .done
        _ = await pause()
    }

    private func loadRoadster() async -> Entity? {
        do {
            return try await Entity(named: "roadster", in: .main)
        } catch {
            logger.error("roadster.usdz failed to load, using the procedural car: \(error.localizedDescription)")
            return nil
        }
    }

    private func waitForFirstFrames() async {
        for _ in 0..<60 {
            if (scene?.renderedFrames ?? 0) >= 10 { return }
            guard await pause(milliseconds: 30) else { return }
        }
    }

    // Short beats so each loading step is visible on the splash bar.
    private func pause(milliseconds: Int = 140) async -> Bool {
        do {
            try await Task.sleep(for: .milliseconds(milliseconds))
            return true
        } catch {
            return false
        }
    }
}
