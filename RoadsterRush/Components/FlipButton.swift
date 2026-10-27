import SwiftUI

struct FlipButton: View {
    let game: GameModel

    @State private var pressed = false

    var body: some View {
        let flipping = game.flipping

        ZStack {
            TimelineView(.animation(paused: !flipping)) { timeline in
                let turn = timeline.date.timeIntervalSinceReferenceDate * 900
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(AppColors.yellow, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(turn.truncatingRemainder(dividingBy: 360)))
                    .opacity(flipping ? 1 : 0)
            }
            .frame(width: 80, height: 80)
            Circle()
                .fill(AppColors.yellow.opacity(pressed || flipping ? 0.75 : 0.28))
                .overlay { Circle().strokeBorder(AppColors.yellow, lineWidth: 2) }
                .frame(width: 66, height: 66)
                .shadow(color: AppColors.yellow.opacity(flipping ? 0.7 : 0.2), radius: flipping ? 14 : 6)
            Text("FLIP")
                .font(AppFonts.ui(16, weight: .bold))
                .foregroundStyle(AppColors.text)
        }
        .frame(width: 80, height: 80)
        .scaleEffect(pressed ? 0.92 : 1)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .contentShape(Circle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    game.flipCar()
                }
                .onEnded { _ in pressed = false }
        )
    }
}
