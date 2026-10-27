import SwiftUI

struct Joystick: View {
    let onChange: (SIMD2<Double>) -> Void
    var autopilot: SIMD2<Double>?

    @State private var knob: CGSize = .zero

    private let size: CGFloat = 144
    private let knobSize: CGFloat = 56
    private let deadzone = 0.08
    private var travel: CGFloat { (size - knobSize) / 2 }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .glass(in: Circle())
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 3, height: 10)
                    .offset(y: -size / 2 + 13)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            Circle()
                .fill(Color.white)
                .frame(width: knobSize, height: knobSize)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                .offset(knobOffset)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { move(to: $0.location) }
                .onEnded { _ in release() }
        )
    }

    private var knobOffset: CGSize {
        guard let autopilot else { return knob }
        return CGSize(width: autopilot.x * travel, height: autopilot.y * travel)
    }

    private func move(to location: CGPoint) {
        let dx = location.x - size / 2
        let dy = location.y - size / 2
        let length = hypot(dx, dy)
        let scale = length > travel ? travel / length : 1
        knob = CGSize(width: dx * scale, height: dy * scale)
        var value = SIMD2(Double(knob.width / travel), Double(knob.height / travel))
        if (value * value).sum().squareRoot() < deadzone { value = .zero }
        onChange(value)
    }

    private func release() {
        withAnimation(.spring(duration: 0.18)) { knob = .zero }
        onChange(.zero)
    }
}
