import SwiftUI

/// Figma 아트보드 크기. 제네릭 타입 안에는 저장 프로퍼티를 둘 수 없어 밖에 뺀다.
private enum Design {
    static let width: CGFloat = 375
    static let height: CGFloat = 812
}

private struct OnboardingVerticalSlackKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct OnboardingCanvasHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = Design.height
}

private struct OnboardingBottomSafeAreaKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// 디자인 높이(812)에서 화면이 모자란 만큼. 디자인 단위다.
    ///
    /// SE(375×667)는 145, iPhone 16과 Pro Max는 0이다. 화면이 짧을 때 아래쪽
    /// 요소를 이만큼 끌어올려 빈 공간에서 빼면, 줄이거나 넘기지 않고도 다 들어온다.
    var onboardingVerticalSlack: CGFloat {
        get { self[OnboardingVerticalSlackKey.self] }
        set { self[OnboardingVerticalSlackKey.self] = newValue }
    }

    /// 가로 기준으로 환산한 실제 캔버스 높이다.
    var onboardingCanvasHeight: CGFloat {
        get { self[OnboardingCanvasHeightKey.self] }
        set { self[OnboardingCanvasHeightKey.self] = newValue }
    }

    /// 가로 기준으로 환산한 하단 safe area다.
    var onboardingBottomSafeArea: CGFloat {
        get { self[OnboardingBottomSafeAreaKey.self] }
        set { self[OnboardingBottomSafeAreaKey.self] = newValue }
    }
}

/// 온보딩 화면들이 공유하는 배치 판.
///
/// Figma 375×812 좌표를 그대로 쓰고, **가로에 맞춰** 판을 늘리고 줄인다.
/// 가로 기준이라 좌우 여백과 화면 끝까지 흐르는 그림이 어느 기기에서나 같다.
///
/// 세로가 모자란 기기에서는 판을 통째로 줄이지 않는다. 줄이면 SE에서 가로가
/// 33.5pt씩 남아 여백이 어긋나고, 세로만 줄이면 동그란 버튼이 타원이 된다.
/// 대신 모자란 만큼을 `onboardingVerticalSlack`으로 알려주고, 화면이 그만큼을
/// 빈 공간에서 빼도록 한다.
struct OnboardingDesignCanvas<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Design.width
            let canvasHeight = proxy.size.height / scale
            let slack = max(0, Design.height - canvasHeight)
            let bottomSafeArea = proxy.safeAreaInsets.bottom / scale

            ZStack(alignment: .topLeading) {
                Color.recapBackground
                content
            }
            .environment(\.onboardingVerticalSlack, slack)
            .environment(\.onboardingCanvasHeight, canvasHeight)
            .environment(\.onboardingBottomSafeArea, bottomSafeArea)
            .frame(width: Design.width, height: Design.height, alignment: .top)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
            .background(Color.recapBackground)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
    }
}

extension View {
    func onboardingFrame(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        alignment: Alignment = .center
    ) -> some View {
        frame(width: width, height: height, alignment: alignment)
            .position(x: x + width / 2, y: y + height / 2)
    }

    /// 화면이 짧은 만큼 위로 끌어올린다. 위에 빈 공간이 있는 요소에 붙인다.
    func onboardingLiftedOnShortScreen() -> some View {
        modifier(OnboardingLift(portion: 1))
    }

    /// 모자란 양의 일부만 나눠 받는다. 여러 자리에 나눠 빼야 겹치지 않을 때 쓴다.
    func onboardingLiftedOnShortScreen(portion: CGFloat) -> some View {
        modifier(OnboardingLift(portion: portion))
    }
}

private struct OnboardingLift: ViewModifier {
    @Environment(\.onboardingVerticalSlack) private var slack

    let portion: CGFloat

    func body(content: Content) -> some View {
        content.offset(y: -slack * portion)
    }
}
