import SwiftUI

struct HowToCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            row(badge: "FLY", color: AppColors.cyan, text: "Hold FLY to rise")
            row(systemImage: "circle.circle", color: AppColors.text, text: "Joystick: steer and aim your landing")
            row(badge: "FLIP", color: AppColors.yellow, text: "Barrel roll dodge, +25 in the air")
            Rectangle().fill(AppColors.glassBorder).frame(height: 1)
            HStack(spacing: 16) {
                legend(color: AppColors.green, text: "Green ring = road")
                legend(color: AppColors.red, text: "Red = cars")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel()
    }

    private func row(badge: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Text(badge)
                .font(AppFonts.ui(9, weight: .bold))
                .foregroundStyle(AppColors.text)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.35), in: Circle())
                .overlay { Circle().strokeBorder(color, lineWidth: 1.5) }
            label(text)
        }
    }

    private func row(systemImage: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .glass(in: Circle())
            label(text)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.ui(14, weight: .medium))
            .foregroundStyle(AppColors.text.opacity(0.88))
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .strokeBorder(color, lineWidth: 2.5)
                .frame(width: 14, height: 14)
            Text(text)
                .font(AppFonts.lcd(9))
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}
