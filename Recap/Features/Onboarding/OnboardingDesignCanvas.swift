import SwiftUI

/// Figma 아트보드 크기. 제네릭 타입 안에는 저장 프로퍼티를 둘 수 없어 밖에 뺀다.
private enum Design {
    static let width: CGFloat = 375
    static let height: CGFloat = 812
}

/// 온보딩 화면들이 공유하는 배치 판.
///
/// Figma 375×812 좌표를 그대로 쓰고, 판을 통째로 늘리고 줄여 화면에 맞춘다.
/// 좌표를 하나하나 옮기지 않아도 되는 대신 배율을 잘 골라야 하는데, 화면마다
/// 비율이 달라서 배율 하나로는 두 마리를 다 잡지 못한다.
///
/// - 가로에 맞추면(`width / 375`) 여백과 배경이 디자인대로지만, SE(375×667)에서는
///   배율이 1이라 판이 812 그대로여서 아래 145pt가 화면 밖으로 나간다. 로그인
///   버튼과 약관이 그 안에 있고 온보딩에는 세로 스크롤이 없어 앱을 시작할 수 없다.
/// - 화면 안에 다 담으면(`min`) 잘리지는 않지만 SE에서 82%로 줄어, 화면 끝까지
///   흘러야 할 배경 그림이 좌우로 33.5pt씩 안쪽으로 밀린다.
///
/// 그래서 층을 나눈다. **배경은 넘치게(`max`), 내용은 담기게(`min`)** 놓는다.
/// 배경은 어차피 잘려도 되는 장식이라 화면을 꽉 채우고, 글자와 버튼은 작아질지언정
/// 다 보인다. SE에서 내용이 82%가 되는 것은 남는 대가다.
struct OnboardingDesignCanvas<Background: View, Content: View>: View {
    private let background: Background
    private let content: Content

    init(
        @ViewBuilder background: () -> Background = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.background = background()
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let widthScale = proxy.size.width / Design.width
            let heightScale = proxy.size.height / Design.height

            ZStack {
                Color.recapBackground

                designLayer(background)
                    .scaleEffect(max(widthScale, heightScale), anchor: .center)

                designLayer(content)
                    .scaleEffect(min(widthScale, heightScale), anchor: .center)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .interactivePopGestureEnabled()
    }

    private func designLayer(_ layer: some View) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            layer
        }
        .frame(width: Design.width, height: Design.height)
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
