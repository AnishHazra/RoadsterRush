import SwiftUI

struct DangerVignette: View {
    var body: some View {
        GeometryReader { proxy in
            let radius = max(proxy.size.width, proxy.size.height)
            RadialGradient(
                colors: [.clear, AppColors.red.opacity(0.18), AppColors.red.opacity(0.5)],
                center: .center,
                startRadius: radius * 0.28,
                endRadius: radius * 0.62
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
