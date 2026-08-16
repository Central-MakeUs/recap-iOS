import SwiftUI

/// 온보딩 화면들이 공유하는 배치 판.
///
/// Figma 375×812 좌표를 그대로 쓰고, 판을 통째로 늘리고 줄여 화면에 맞춘다.
/// 좌표를 하나하나 옮기지 않아도 되는 대신 배율을 잘 골라야 한다.
///
/// 가로만 보고 맞추면 SE(375×667)에서 배율이 1이라 판이 812 그대로여서
/// 아래 145pt가 화면 밖으로 나간다. 로그인 버튼과 약관이 그 안에 있고
/// 온보딩에는 세로 스크롤이 없어, 첫 화면에서 앱을 시작할 수 없게 된다.
///
/// 그래서 가로·세로 중 더 빡빡한 쪽에 맞춘다. SE에서는 세로가 기준이 되어
/// 82%로 줄고, iPhone 16과 Pro Max는 세로 비율이 812에 가까워 가로 기준
/// 그대로다. 배경색이 판 밖을 채우므로 줄어든 자리가 드러나지 않는다.
/// Figma 아트보드 크기. 제네릭 타입 안에는 저장 프로퍼티를 둘 수 없어 밖에 뺀다.
private enum Design {
    static let width: CGFloat = 375
    static let height: CGFloat = 812
}

struct OnboardingDesignCanvas<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            // 가로·세로 중 더 빡빡한 쪽에 맞춘다. 가로만 보면 SE에서 배율이 1이라
            // 판이 812 그대로여서 아래 145pt가 화면 밖으로 나가고, 그 안에 있는
            // 하단 버튼에 손이 닿지 않는다.
            let scale = min(
                proxy.size.width / Design.width,
                proxy.size.height / Design.height
            )

            ZStack(alignment: .topLeading) {
                Color.recapBackground
                content
            }
            .frame(width: Design.width, height: Design.height)
            .scaleEffect(scale, anchor: .center)
            .frame(width: proxy.size.width, height: proxy.size.height)
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
}
