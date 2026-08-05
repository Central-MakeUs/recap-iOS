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

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        // 캐러셀처럼 화면 밖에서 미리 생성된 뷰는 최초 play가 무시될 수 있어
        // 업데이트 시점에 재생을 보장한다. 1회 재생은 끝난 뒤 다시 시작하지 않는다.
        guard !animationView.isAnimationPlaying else { return }

        switch playback {
        case .loop:
            animationView.play()
        case .playOnce:
            if animationView.currentProgress < 1 {
                animationView.play()
            }
        }
    }
}
