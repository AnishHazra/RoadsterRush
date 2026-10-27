import SwiftUI

struct GlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background { shape.fill(Color.black.opacity(0.5)) }
            .background(.ultraThinMaterial, in: shape)
            .overlay { shape.strokeBorder(AppColors.glassBorder, lineWidth: 1) }
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 14) -> some View {
        modifier(GlassModifier(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)))
    }

    func glass<S: InsettableShape>(in shape: S) -> some View {
        modifier(GlassModifier(shape: shape))
    }
}
