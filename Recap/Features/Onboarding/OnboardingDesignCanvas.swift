import SwiftUI

/// Figma 아트보드 크기. 제네릭 타입 안에는 저장 프로퍼티를 둘 수 없어 밖에 뺀다.
private enum Design {
    static let width: CGFloat = 375
    static let height: CGFloat = 812
}

/// 온보딩 화면들이 공유하는 배치 판.
///
/// Figma 375×812 좌표를 그대로 쓰고, **가로에 맞춰** 판을 늘리고 줄인다.
/// 가로 기준이라 좌우 여백과 화면 끝까지 흐르는 그림이 어느 기기에서나 같다.
///
/// 세로는 기기마다 비율이 달라 남거나 모자란다. 모자랄 때는 넘겨볼 수 있게 한다.
/// SE(375×667)가 그런 경우로, 배율이 1이라 판이 812 그대로여서 아래 145pt가
/// 화면 밖으로 나간다. 로그인 버튼과 약관이 그 안에 있어 넘겨보지 못하면 앱을
/// 시작할 수 없다. iPhone 16과 Pro Max는 세로 비율이 812에 가까워 넘길 것이 없다.
///
/// 판을 화면에 맞춰 줄이는 방법도 있지만 그러면 안 된다. SE는 비율이 0.562로
/// Pro Max(0.461)보다 가로로 뚱뚱해서, 세로에 맞추면 가로가 33.5pt씩 남는다.
/// 글자 여백이 27에서 52로 벌어지고, 화면 끝까지 흘러야 할 그림이 안쪽으로
/// 밀린다. 기기마다 여백이 달라지느니 넘겨보는 편이 낫다.
struct OnboardingDesignCanvas<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Design.width
            let scaledHeight = Design.height * scale

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    Color.recapBackground
                    content
                }
                .frame(width: Design.width, height: Design.height)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: proxy.size.width, height: scaledHeight, alignment: .topLeading)
            }
            // 판이 화면에 들어오면 넘길 것이 없으므로 잠근다. 큰 기기에서 손가락이
            // 미끄러져 화면이 흔들리는 일을 막는다.
            .scrollDisabled(scaledHeight <= proxy.size.height)
            .scrollBounceBehavior(.basedOnSize)
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
