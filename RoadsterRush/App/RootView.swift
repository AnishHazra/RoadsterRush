import SwiftUI

struct RootView: View {
    @State private var game = GameModel(sounds: SoundService(), haptics: HapticsService())
    @State private var loader = AssetLoader()
    @State private var screen: AppScreen = .splash

    @AppStorage(SettingsKeys.bestScore) private var bestScore = 0
    @AppStorage(SettingsKeys.soundEnabled) private var soundOn = true
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsOn = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if let scene = loader.scene {
                GameSceneView(scene: scene)
                    .ignoresSafeArea()
                    .blur(radius: screen == .game && game.state == .crashed ? 3 : 0)
                    .animation(.easeOut(duration: 0.4), value: game.state)
            }

            switch screen {
            case .splash:
                SplashView(progress: loader.progress, status: loader.failure ?? loader.stage.status)
                    .transition(.opacity)
            case .title:
                TitleView(best: bestScore, soundOn: $soundOn, onStart: startGame)
                    .transition(.opacity)
            case .game:
                GameView(game: game, soundOn: $soundOn, hapticsOn: $hapticsOn, onQuit: quitToTitle)
                    .transition(.opacity)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        // Otherwise iOS holds back touches near the edges to check for a home swipe
        .defersSystemGestures(on: screen == .game ? .all : [])
        .task {
            game.setBest(bestScore)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-demo") { game.enableDemo() }
            #endif
            await loader.load(game: game)
            guard loader.scene != nil else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                screen = game.demo ? .game : .title
            }
        }
        .onChange(of: soundOn, initial: true) { _, on in game.sounds.isEnabled = on }
        .onChange(of: hapticsOn, initial: true) { _, on in game.haptics.isEnabled = on }
        .onChange(of: game.best) { _, best in
            if best > bestScore { bestScore = best }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                game.sounds.startEngine()
            } else {
                game.pause()
                if phase == .background { game.sounds.stopEngine() }
            }
        }
    }

    private func startGame() {
        game.start()
        withAnimation(.easeInOut(duration: 0.3)) { screen = .game }
    }

    private func quitToTitle() {
        game.returnToTitle()
        withAnimation(.easeInOut(duration: 0.3)) { screen = .title }
    }
}
