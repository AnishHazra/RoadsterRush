import SwiftUI

struct StatusPill: View {
    let game: GameModel

    var body: some View {
        if let status {
            HStack(spacing: 7) {
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
                    .shadow(color: status.color, radius: 3)
                Text(status.text)
                    .font(AppFonts.lcd(11))
                    .foregroundStyle(status.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .glass(in: Capsule())
            .overlay { Capsule().strokeBorder(status.color.opacity(0.45), lineWidth: 1) }
            .transition(.opacity)
        }
    }

    private var status: (text: String, color: Color)? {
        guard game.state == .playing else { return nil }
        if game.isAirborne {
            return game.landingOnCars ? ("LANDING CARS", AppColors.red) : ("LANDING ROAD", AppColors.green)
        }
        guard let ahead = game.stackAhead else { return nil }
        return ahead < 22 ? ("HOLD FLY", AppColors.red) : ("STACK AHEAD \(ahead)M", AppColors.yellow)
    }
}
