import SwiftUI

struct HUDView: View {
    let game: GameModel

    var body: some View {
        let progress = 1 - Double(game.metersToNextLevel) / GameModel.levelLength

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SCORE")
                        .font(AppFonts.lcd(9))
                        .foregroundStyle(AppColors.yellow)
                    LCDNumber(value: game.score, digits: 5)
                }
                Rectangle()
                    .fill(AppColors.glassBorder)
                    .frame(width: 1, height: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text("LVL")
                        .font(AppFonts.lcd(9))
                        .foregroundStyle(AppColors.yellow)
                    LCDNumber(value: game.level, digits: 2)
                }
            }
            HStack(spacing: 8) {
                Capsule()
                    .fill(AppColors.track)
                    .frame(width: 116, height: 3)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.yellow)
                            .frame(width: 116 * progress, height: 3)
                    }
                Text("\(game.metersToNextLevel) M")
                    .font(AppFonts.lcd(9))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(12)
        .glassPanel()
    }
}
