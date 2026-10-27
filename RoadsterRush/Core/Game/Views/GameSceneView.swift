import RealityKit
import SwiftUI

struct GameSceneView: View {
    let scene: GameScene

    var body: some View {
        RealityView { content in
            scene.install(in: &content)
        }
    }
}
