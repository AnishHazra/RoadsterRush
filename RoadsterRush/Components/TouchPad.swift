import SwiftUI
import UIKit

// Raw UIKit touches: SwiftUI gestures hold back a lone first touch before reporting it
struct TouchPad: UIViewRepresentable {
    let onChange: (Bool) -> Void

    func makeUIView(context: Context) -> PadView {
        let view = PadView()
        view.backgroundColor = .clear
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: PadView, context: Context) {
        view.onChange = onChange
    }

    final class PadView: UIView {
        var onChange: ((Bool) -> Void)?

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let dx = point.x - bounds.midX
            let dy = point.y - bounds.midY
            return hypot(dx, dy) <= min(bounds.width, bounds.height) / 2
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            onChange?(true)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            onChange?(false)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            onChange?(false)
        }
    }
}
