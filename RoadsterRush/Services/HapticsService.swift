import UIKit

final class HapticsService {
    var isEnabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    func tick() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.7)
    }

    func hardLanding() {
        guard isEnabled else { return }
        medium.impactOccurred()
    }

    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func crash() {
        guard isEnabled else { return }
        heavy.impactOccurred()
    }
}
