import SwiftUI

struct SplashView: View {
    let progress: Double
    let status: String

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [AppColors.splashGlow, AppColors.background],
                center: .center,
                startRadius: 0,
                endRadius: 460
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                Text("F1 RACE · REIMAGINED")
                    .font(AppFonts.lcd(11))
                    .tracking(2)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.bottom, 18)
                RoadsterLogo()
                Spacer()
                LoadingBar(progress: progress)
                Text(status)
                    .font(AppFonts.lcd(10))
                    .tracking(1.5)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, 12)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: status)
                Spacer().frame(height: 64)
                Text("Non-commercial fan project")
                    .font(AppFonts.ui(12))
                    .foregroundStyle(AppColors.tertiaryText)
                    .padding(.bottom, 12)
            }
        }
    }
}

private struct LoadingBar: View {
    let progress: Double
    private let segments = 12

    var body: some View {
        let filled = Int((progress * Double(segments)).rounded(.down))
        HStack(spacing: 4) {
            ForEach(0..<segments, id: \.self) { index in
                let on = index < filled
                RoundedRectangle(cornerRadius: 2)
                    .fill(on ? AppColors.cyan : AppColors.track)
                    .frame(width: 16, height: 10)
                    .shadow(color: on ? AppColors.cyan.opacity(0.8) : .clear, radius: 4)
            }
        }
        .animation(.easeOut(duration: 0.15), value: filled)
    }
}
