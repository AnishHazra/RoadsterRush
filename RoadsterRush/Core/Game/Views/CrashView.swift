import SwiftUI

struct CrashView: View {
    let game: GameModel
    let onHome: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.red.opacity(0.5), Color.black.opacity(0.78), Color.black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                if game.isNewBest {
                    Text("NEW BEST")
                        .font(AppFonts.lcd(12, bold: true))
                        .foregroundStyle(AppColors.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(AppColors.yellow, in: Capsule())
                        .shadow(color: AppColors.yellow.opacity(0.6), radius: 10)
                }
                crashTitle
                Text("Landed on the Teslas at level \(game.level).")
                    .font(AppFonts.ui(15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)

                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        Text("SCORE")
                            .font(AppFonts.lcd(10))
                            .foregroundStyle(AppColors.yellow)
                        LCDNumber(value: game.score, digits: 5, size: 46)
                    }
                    Rectangle().fill(AppColors.glassBorder).frame(height: 1)
                    HStack {
                        StatCell(label: "BEST", value: "\(game.best)")
                        StatCell(label: "LVL", value: "\(game.level)")
                        StatCell(label: "DIST", value: "\(game.distance)M")
                        StatCell(label: "FLIPS", value: "\(game.flips)")
                    }
                }
                .padding(18)
                .glassPanel()

                HStack(spacing: 12) {
                    Button("RETRY") { game.start() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("HOME", action: onHome)
                        .buttonStyle(GlassButtonStyle())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private var crashTitle: some View {
        ZStack {
            Text("CRASH!").foregroundStyle(AppColors.cyan).offset(x: -4, y: 2)
            Text("CRASH!").foregroundStyle(AppColors.yellow).offset(x: 4, y: -2)
            Text("CRASH!").foregroundStyle(AppColors.red)
        }
        .font(AppFonts.title(72))
    }
}
