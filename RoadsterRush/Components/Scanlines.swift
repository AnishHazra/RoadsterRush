import SwiftUI

struct Scanlines: View {
    var spacing: CGFloat = 3

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.45)))
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}
