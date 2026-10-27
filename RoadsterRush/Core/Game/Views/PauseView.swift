import SwiftUI

struct PauseView: View {
    let game: GameModel
    @Binding var soundOn: Bool
    @Binding var hapticsOn: Bool
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.55))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text("RUN ON HOLD")
                        .font(AppFonts.lcd(11))
                        .tracking(2)
                        .foregroundStyle(AppColors.secondaryText)
                    Text("PAUSED")
                        .font(AppFonts.title(56))
                        .foregroundStyle(AppColors.text)
                }

                HStack {
                    StatCell(label: "SCORE", value: "\(game.score)")
                    StatCell(label: "LVL", value: "\(game.level)")
                    StatCell(label: "DIST", value: "\(game.distance)M")
                }
                .padding(.vertical, 14)
                .glassPanel()

                VStack(spacing: 10) {
                    Button("RESUME") { game.resume() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("RESTART") { game.start() }
                        .buttonStyle(GlassButtonStyle())
                }

                VStack(spacing: 0) {
                    toggleRow("Sound", systemImage: "speaker.wave.2.fill", isOn: $soundOn)
                    Rectangle().fill(AppColors.glassBorder).frame(height: 1)
                    toggleRow("Haptics", systemImage: "iphone.radiowaves.left.and.right", isOn: $hapticsOn)
                }
                .glassPanel()

                Button("QUIT TO TITLE", action: onQuit)
                    .font(AppFonts.ui(14, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
        }
    }

    private func toggleRow(_ title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: systemImage)
                .font(AppFonts.ui(16, weight: .medium))
                .foregroundStyle(AppColors.text)
        }
        .tint(AppColors.cyan)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
