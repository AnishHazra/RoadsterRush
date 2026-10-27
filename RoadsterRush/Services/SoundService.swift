import AVFoundation
import os

final class SoundService {
    enum Effect: String, CaseIterable {
        case flip
        case land
        case crash
        case bonus

        var volume: Float {
            switch self {
            case .flip: 0.8
            case .land: 0.7
            case .crash: 0.9
            case .bonus: 0.5
            }
        }
    }

    var isEnabled = true {
        didSet { engine.mainMixerNode.outputVolume = isEnabled ? 1 : 0 }
    }

    private let logger = Logger(subsystem: "RoadsterRush", category: "Sound")
    private let engine = AVAudioEngine()
    private let thrustLoop = AVAudioPlayerNode()
    private let sideLoop = AVAudioPlayerNode()
    private var shotPlayers: [AVAudioPlayerNode] = []
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var thrustBuffer: AVAudioPCMBuffer?
    private var sideBuffer: AVAudioPCMBuffer?
    private var nextShot = 0
    private var isLoaded = false

    func load() async {
        guard !isLoaded else { return }
        isLoaded = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio session failed: \(error.localizedDescription)")
        }

        thrustBuffer = Self.buffer(named: "thrust")
        sideBuffer = Self.buffer(named: "side_jet")
        for effect in Effect.allCases {
            buffers[effect] = Self.buffer(named: effect.rawValue)
        }
        guard let format = thrustBuffer?.format ?? buffers.values.first?.format else {
            logger.error("No sound files found in bundle")
            return
        }

        for node in [thrustLoop, sideLoop] {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            node.volume = 0
        }
        for _ in 0..<6 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            shotPlayers.append(node)
        }
        startEngine()
    }

    func startEngine() {
        guard isLoaded, !engine.isRunning, !shotPlayers.isEmpty else { return }
        do {
            try engine.start()
        } catch {
            logger.error("Audio engine failed to start: \(error.localizedDescription)")
            return
        }
        if let thrustBuffer {
            thrustLoop.scheduleBuffer(thrustBuffer, at: nil, options: .loops)
            thrustLoop.play()
        }
        if let sideBuffer {
            sideLoop.scheduleBuffer(sideBuffer, at: nil, options: .loops)
            sideLoop.play()
        }
    }

    func stopEngine() {
        guard engine.isRunning else { return }
        thrustLoop.stop()
        sideLoop.stop()
        shotPlayers.forEach { $0.stop() }
        engine.stop()
    }

    func loops(thrust: Double, side: Double) {
        let thrustVolume = Float(thrust * 0.7)
        let sideVolume = Float(side * 0.45)
        if abs(thrustLoop.volume - thrustVolume) >= 0.03 || thrustVolume == 0 { thrustLoop.volume = thrustVolume }
        if abs(sideLoop.volume - sideVolume) >= 0.03 || sideVolume == 0 { sideLoop.volume = sideVolume }
    }

    func flip() { play(.flip) }
    func land() { play(.land) }
    func crash() { play(.crash) }
    func bonus() { play(.bonus) }

    private func play(_ effect: Effect) {
        guard isEnabled, engine.isRunning, let buffer = buffers[effect], !shotPlayers.isEmpty else { return }
        let player = shotPlayers[nextShot]
        nextShot = (nextShot + 1) % shotPlayers.count
        player.stop()
        player.volume = effect.volume
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    private static func buffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: buffer)
            return buffer
        } catch {
            Logger(subsystem: "RoadsterRush", category: "Sound").error("Failed to read \(name).wav: \(error.localizedDescription)")
            return nil
        }
    }
}
