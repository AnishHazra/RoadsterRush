import SwiftUI

struct FlipPopup: View {
    let flips: Int

    @State private var trigger = 0

    var body: some View {
        Text("FLIP +\(GameModel.flipPoints)")
            .font(AppFonts.lcd(32, bold: true))
            .foregroundStyle(AppColors.yellow)
            .shadow(color: AppColors.yellow.opacity(0.9), radius: 10)
            .keyframeAnimator(initialValue: 1.0, trigger: trigger) { content, progress in
                content
                    .opacity(progress >= 1 ? 0 : 1 - progress)
                    .offset(y: -150 - progress * 70)
            } keyframes: { _ in
                MoveKeyframe(0.0)
                CubicKeyframe(1.0, duration: 0.9)
            }
            .allowsHitTesting(false)
            .onChange(of: flips) { old, new in
                if new > old { trigger += 1 }
            }
    }
}
