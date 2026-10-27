import SwiftUI

// Seven-segment look: ghost "888" behind the value, leading zeros drawn dim.
struct LCDNumber: View {
    let value: Int
    let digits: Int
    var size: CGFloat = 22
    var color: Color = AppColors.text

    var body: some View {
        let limit = Int(pow(10, Double(digits))) - 1
        let shown = String(min(max(value, 0), limit))
        let zeros = String(repeating: "0", count: max(0, digits - shown.count))

        ZStack(alignment: .trailing) {
            Text(String(repeating: "8", count: digits))
                .foregroundStyle(AppColors.lcdGhost)
            HStack(spacing: 0) {
                Text(zeros).foregroundStyle(AppColors.lcdZero)
                Text(shown).foregroundStyle(color)
            }
        }
        .font(AppFonts.lcd(size))
        .lineLimit(1)
        .fixedSize()
    }
}
