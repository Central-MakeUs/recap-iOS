import Lottie
import SwiftUI

/// 번들에 포함된 Lottie 애니메이션을 재생한다.
///
/// - `loop`: 뷰가 사라질 때까지 무한 반복한다.
/// - `playOnce`: 1회 재생 후 마지막 프레임에서 멈춘다.
struct RecapLottieView: UIViewRepresentable {
    enum Playback {
        case loop
        case playOnce
    }

    let name: String
    var playback: Playback = .loop

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.loopMode = playback == .loop ? .loop : .playOnce
        animationView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        animationView.setContentHuggingPriority(.defaultLow, for: .vertical)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        animationView.play()
        return animationView
    }

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {}
}
