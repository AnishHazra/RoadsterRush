import SwiftUI

struct RoadsterLogo: View {
    var scale: CGFloat = 1
    var stacked = true

    var body: some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(spacing: 10 * scale))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12 * scale))
        layout {
            Text("ROADSTER")
                .font(AppFonts.title(56 * scale))
                .foregroundStyle(AppColors.text)
                .shadow(color: AppColors.cyan.opacity(0.25), radius: 18)
            hop
        }
    }

    private var hop: some View {
        Text("HOP")
            .font(AppFonts.lcd(34 * scale, bold: true))
            .foregroundStyle(AppColors.cyan)
            .shadow(color: AppColors.cyan.opacity(0.9), radius: 6 * scale)
            .padding(.horizontal, 16 * scale)
            .padding(.vertical, 6 * scale)
            .background(Color.black.opacity(0.65))
            .overlay(Scanlines())
            .clipShape(RoundedRectangle(cornerRadius: 6 * scale))
            .overlay {
                RoundedRectangle(cornerRadius: 6 * scale)
                    .strokeBorder(AppColors.cyan, lineWidth: 1.5)
            }
            .shadow(color: AppColors.cyan.opacity(0.45), radius: 14 * scale)
    }
}
