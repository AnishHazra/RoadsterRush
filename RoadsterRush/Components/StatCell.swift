import SwiftUI

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppFonts.lcd(9))
                .foregroundStyle(AppColors.yellow)
            Text(value)
                .font(AppFonts.lcd(17))
                .foregroundStyle(AppColors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}
