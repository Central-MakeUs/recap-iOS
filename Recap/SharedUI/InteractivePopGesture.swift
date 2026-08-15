import SwiftUI
import UIKit

/// 내비게이션 바를 숨긴 화면에서도 왼쪽 가장자리 스와이프로 뒤로 갈 수 있게 한다.
///
/// `NavigationStack`은 내부적으로 `UINavigationController`로 동작하고, 뒤로 스와이프는
/// 그 컨트롤러의 `interactivePopGestureRecognizer`가 담당한다. 이 제스처는 기본
/// 뒤로가기 버튼과 한 몸이라 `.toolbar(.hidden, for: .navigationBar)`나
/// `.navigationBarBackButtonHidden(true)`를 쓰면 함께 꺼진다.
///
/// 이 앱은 화면마다 자체 헤더를 그리므로 바를 되살릴 수 없다. 대신 제스처의
/// delegate를 넘겨받아 스택에 화면이 쌓여 있을 때 항상 인식하도록 되돌린다.
///
/// delegate는 약한 참조다. 화면마다 delegate를 만들면 그 화면이 pop되는 순간
/// 함께 해제되어 제스처가 다시 죽는다. 그래서 앱 전체가 하나를 공유한다.
@MainActor
private final class InteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = InteractivePopGestureDelegate()

    private override init() {
        super.init()
    }

    func restore(on navigationController: UINavigationController) {
        guard let gesture = navigationController.interactivePopGestureRecognizer else { return }
        gesture.isEnabled = true
        gesture.delegate = self
    }

    /// 탭마다 `UINavigationController`가 따로 있으므로 제스처가 붙은 뷰에서
    /// 거슬러 올라가 그때그때 찾는다. 특정 컨트롤러를 붙잡아 두지 않는다.
    private func navigationController(for gesture: UIGestureRecognizer) -> UINavigationController? {
        var responder = gesture.view?.next
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }

    nonisolated func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        MainActor.assumeIsolated {
            // 루트 화면에서는 뒤로 갈 곳이 없다.
            guard let navigationController = navigationController(for: gestureRecognizer) else {
                return false
            }
            return navigationController.viewControllers.count > 1
        }
    }

    /// 다른 제스처와 동시에 인식되지 않게 한다.
    /// 허용하면 가로 스크롤이 있는 화면에서 둘 다 반응한다.
    nonisolated func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        false
    }
}

private struct InteractivePopGestureRestorer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ProbeViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let navigationController = uiViewController.navigationController else { return }
        InteractivePopGestureDelegate.shared.restore(on: navigationController)
    }

    /// 뷰 계층에 붙는 시점에 `navigationController`가 잡히므로 그때도 한 번 건다.
    private final class ProbeViewController: UIViewController {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            guard let navigationController else { return }
            InteractivePopGestureDelegate.shared.restore(on: navigationController)
        }
    }
}

extension View {
    /// 내비게이션 바를 숨긴 화면에 붙여 스와이프 뒤로가기를 되살린다.
    /// `.toolbar(.hidden, for: .navigationBar)`와 함께 쓴다.
    ///
    /// 나가기 전에 확인을 받는 화면에는 붙이지 않는다. 스와이프는 그 확인을
    /// 우회하므로 작성 중이던 내용이 사라진다. 현재 `CardEditView`(편집 중단
    /// 확인)와 `CardCreationFlowView`(정리 취소 확인)가 여기 해당한다.
    func interactivePopGestureEnabled() -> some View {
        background(
            InteractivePopGestureRestorer()
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        )
    }
}
