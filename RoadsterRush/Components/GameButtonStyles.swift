import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.ui(18, weight: .bold))
            .tracking(2)
            .foregroundStyle(AppColors.background)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(AppColors.cyan, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppColors.cyan.opacity(configuration.isPressed ? 0.2 : 0.45), radius: 16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.ui(18, weight: .bold))
            .tracking(2)
            .foregroundStyle(AppColors.text)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .glassPanel()
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
