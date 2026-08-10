import Lottie
import SwiftUI

/// 번들에 포함된 Lottie 애니메이션을 재생한다.
///
/// - `loop`: 뷰가 사라질 때까지 무한 반복한다.
/// - `playOnce`: 1회 재생 후 마지막 프레임에서 멈춘다.
struct RecapLottieView: View {
    enum Playback {
        case loop
        case playOnce
    }

    let name: String
    var playback: Playback = .loop

    var body: some View {
        LottieView(animation: .named(name))
            .playing(loopMode: playback == .loop ? .loop : .playOnce)
            .resizable()
            .backgroundBehavior(.pauseAndRestore)
    }
}
