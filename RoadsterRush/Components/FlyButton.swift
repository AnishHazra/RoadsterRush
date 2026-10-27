import SwiftUI

struct FlyButton: View {
    let game: GameModel

    @State private var pressed = false

    var body: some View {
        let air = game.air
        let low = air < 0.25
        let active = pressed || game.flying

        ZStack {
            Circle()
                .stroke(AppColors.track, lineWidth: 5)
            Circle()
                .trim(from: 0, to: air)
                .stroke(low ? AppColors.red : AppColors.cyan, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: (low ? AppColors.red : AppColors.cyan).opacity(0.6), radius: 4)
            Circle()
                .fill(AppColors.cyan.opacity(active ? 0.75 : 0.32))
                .overlay { Circle().strokeBorder(AppColors.cyan, lineWidth: 2) }
                .frame(width: 100, height: 100)
                .shadow(color: AppColors.cyan.opacity(active ? 0.7 : 0.25), radius: active ? 16 : 8)
            VStack(spacing: 2) {
                Text("FLY")
                    .font(AppFonts.ui(24, weight: .bold))
                    .foregroundStyle(AppColors.text)
                Text("AIR \(Int((air * 100).rounded()))")
                    .font(AppFonts.lcd(10))
                    .foregroundStyle(low ? AppColors.red : AppColors.text.opacity(0.85))
            }
        }
        .frame(width: 124, height: 124)
        .scaleEffect(pressed ? 0.94 : 1)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .contentShape(Circle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    game.thrust(true)
                }
                .onEnded { _ in
                    pressed = false
                    game.thrust(false)
                }
        )
    }
}
