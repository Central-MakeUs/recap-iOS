import SwiftUI
import UIKit

/// 반경을 지정할 수 있는 백드롭 블러.
///
/// SwiftUI `Material`은 블러 반경을 못 정하고 디자인 사양(예: 토스트의 "흐림 8,
/// 고르게")보다 훨씬 강하게 뭉갠다. `UIBlurEffect`를 애니메이터로 도중에 멈춰
/// 원하는 세기만 적용하는, 널리 쓰이는 기법으로 반경을 흉내 낸다.
///
/// 공개 API만 쓰지만 문서화된 동작은 아니므로, OS 업데이트 후 토스트 배경이
/// 이상해지면 이 파일부터 의심한다.
struct RecapBackdropBlur: UIViewRepresentable {
    /// 디자인 도구의 블러 반경에 대응하는 값.
    let radius: CGFloat

    /// 진행률→반경 환산 상수. iOS 26 시뮬레이터에서 진행률 0.033이 약 2pt로
    /// 번지는 것을 실측해 역산했다(소구간에서 대략 선형).
    private static let maximumRadius: CGFloat = 60

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: nil)
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            view.effect = UIBlurEffect(style: .light)
        }
        animator.pausesOnCompletion = true
        animator.fractionComplete = min(1, radius / Self.maximumRadius)
        context.coordinator.animator = animator
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        context.coordinator.animator?.fractionComplete = min(1, radius / Self.maximumRadius)
    }

    static func dismantleUIView(_ uiView: UIVisualEffectView, coordinator: Coordinator) {
        coordinator.animator?.stopAnimation(true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// 애니메이터가 해제되면 블러도 풀리므로 뷰와 수명을 같이한다.
    final class Coordinator {
        var animator: UIViewPropertyAnimator?
    }
}
