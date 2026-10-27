import SwiftUI

struct TitleView: View {
    let best: Int
    @Binding var soundOn: Bool
    let onStart: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: AppColors.background.opacity(0.55), location: 0),
                    .init(color: .clear, location: 0.14),
                    .init(color: .clear, location: 0.5),
                    .init(color: AppColors.background.opacity(0.9), location: 0.66),
                    .init(color: AppColors.background, location: 0.74),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topRow
                Spacer()
                VStack(spacing: 14) {
                    Text("F1 RACE · REIMAGINED")
                        .font(AppFonts.lcd(10))
                        .tracking(2)
                        .foregroundStyle(AppColors.secondaryText)
                    RoadsterLogo(scale: 0.72, stacked: false)
                    Text("Fly the new 2026 Tesla Roadster over piles of parked Teslas.")
                        .font(AppFonts.ui(15, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    Button("TAP TO START", action: onStart)
                        .buttonStyle(PrimaryButtonStyle(height: 60))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    private var topRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text("BEST")
                    .font(AppFonts.lcd(9))
                    .foregroundStyle(AppColors.yellow)
                LCDNumber(value: best, digits: 5, size: 16)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .glass(in: Capsule())

            Spacer()

            Button {
                soundOn.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(soundOn ? "SFX ON" : "SFX OFF")
                        .font(AppFonts.lcd(10))
                }
                .foregroundStyle(soundOn ? AppColors.cyan : AppColors.secondaryText)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .glass(in: Capsule())
            }
        }
    }
}
