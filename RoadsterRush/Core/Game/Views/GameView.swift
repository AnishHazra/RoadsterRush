import SwiftUI

struct GameView: View {
    let game: GameModel
    @Binding var soundOn: Bool
    @Binding var hapticsOn: Bool
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            if game.landingOnCars && game.isLive {
                DangerVignette()
                    .transition(.opacity)
            }

            if game.state != .crashed {
                hud
                controls
                FlipPopup(flips: game.flips)
            }

            if game.isPaused {
                PauseView(game: game, soundOn: $soundOn, hapticsOn: $hapticsOn, onQuit: onQuit)
                    .transition(.opacity)
            }

            if game.state == .crashed {
                CrashView(game: game, onHome: onQuit)
                    .transition(.opacity.animation(.easeOut(duration: 0.35).delay(0.45)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: game.landingOnCars)
        .animation(.easeOut(duration: 0.2), value: game.isPaused)
    }

    private var hud: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HUDView(game: game)
                Spacer()
                Button {
                    game.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.text)
                        .frame(width: 44, height: 44)
                        .glass(in: Circle())
                }
            }
            StatusPill(game: game)
                .animation(.easeOut(duration: 0.15), value: game.stackAhead)
                .animation(.easeOut(duration: 0.15), value: game.isAirborne)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var controls: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Joystick(onChange: game.setStick, autopilot: game.demo ? game.stick : nil)
                    .padding(.bottom, 12)
                Spacer()
                VStack(spacing: 14) {
                    FlipButton(game: game)
                    FlyButton(game: game)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
    }
}
