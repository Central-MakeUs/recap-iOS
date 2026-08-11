import SwiftUI

struct CardCreationProcessingView: View {
    /// Figma 03-03_정리 시작(375x812) 기준 절대 y 좌표.
    private enum Layout {
        static let titleTop: CGFloat = 240
        static let subtitleTop: CGFloat = 276
        static let animationTop: CGFloat = 280
        static let animationSize: CGFloat = 240
        static let progressBarTop: CGFloat = 509
        static let bubbleTop: CGFloat = 540
    }

    let progress: Double
    let notificationsEnabled: Bool
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Text("스크린샷을 분석 · 정리 하고있어요")
                .font(RecapFont.pretendard(size: 18, weight: .semibold))
                .tracking(-0.36)
                .foregroundStyle(Color.recapGray900)
                .padding(.top, Layout.titleTop)

            Text(subtitle)
                .font(RecapFont.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(Color.recapGray500)
                .padding(.top, Layout.subtitleTop)

            RecapLottieView(name: "analyzing", playback: .loop)
                .frame(width: Layout.animationSize, height: Layout.animationSize)
                .padding(.top, Layout.animationTop)

            CardCreationProgressBar(progress: progress)
                .frame(height: 4)
                .padding(.horizontal, 30)
                .padding(.top, Layout.progressBarTop)

            CardCreationProcessingBubble()
                .padding(.top, Layout.bubbleTop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            RecapButton(
                title: "정리 취소",
                style: .secondary,
                action: onCancel
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 31)
        }
        .background(Color.recapBackground)
        // Figma 좌표는 상태 바를 포함한 화면 최상단 기준이다.
        .ignoresSafeArea(.container, edges: [.top, .bottom])
    }

    private var subtitle: String {
        if notificationsEnabled {
            "정리가 끝나면 바로 알려드릴게요!"
        } else {
            "정리 결과는 앱에서 확인할 수 있어요!"
        }
    }
}

/// 위쪽 꼬리가 달린 말풍선. 2초 주기로 4pt 위아래로 움직인다.
private struct CardCreationProcessingBubble: View {
    private enum Layout {
        static let bodySize = CGSize(width: 189, height: 54)
        static let tailSize = CGSize(width: 16, height: 6)
        static let cornerRadius: CGFloat = 27.68
    }

    @State private var isFloating = false

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(.white)
                .strokeBorder(Color.recapBlue300, lineWidth: 1)
                .frame(width: Layout.bodySize.width, height: Layout.bodySize.height)
                .padding(.top, Layout.tailSize.height)

            BubbleTailShape()
                .fill(.white)
                .overlay {
                    BubbleTailEdgesShape()
                        .stroke(Color.recapBlue300, lineWidth: 1)
                }
                .frame(width: Layout.tailSize.width, height: Layout.tailSize.height + 1)

            Text("앱을 종료해도 백그라운드에서\n정리가 계속 진행돼요!")
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.recapBlue300)
                .frame(
                    width: Layout.bodySize.width,
                    height: Layout.bodySize.height,
                    alignment: .center
                )
                .padding(.top, Layout.tailSize.height)
        }
        .frame(
            width: Layout.bodySize.width,
            height: Layout.bodySize.height + Layout.tailSize.height
        )
        .offset(y: isFloating ? -4 : 0)
        // `onAppear`에서 `withAnimation`으로 걸면 뷰가 트랜잭션보다 먼저 나타나는
        // 경우에 반복 애니메이션이 붙지 않는다. 값 변화에 직접 거는 편이 견고하다.
        .animation(
            .easeInOut(duration: 1).repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear { isFloating = true }
    }
}

/// 꼬리 삼각형 채움. 말풍선 몸통 테두리를 덮도록 1pt 겹친다.
private struct BubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 꼬리 삼각형의 빗변 두 개만 그린다. 밑변은 몸통과 이어져야 하므로 긋지 않는다.
private struct BubbleTailEdgesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

struct CardCreationProgressBar: View {
    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.recapGray100)

                Capsule()
                    .fill(Color.recapBlue300)
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("스크린샷 정리 진행률")
        .accessibilityValue("\(Int(clampedProgress * 100))퍼센트")
        .animation(.linear(duration: 0.25), value: clampedProgress)
    }
}

#if DEBUG
#Preview("CardCreation progress bar") {
    CardCreationProgressBar(progress: 0.75)
        .frame(width: 315, height: 4)
        .padding()
}

#Preview("정리 진행 - 알림 허용") {
    CardCreationProcessingView(
        progress: 0.75,
        notificationsEnabled: true,
        onCancel: {}
    )
}

#Preview("정리 진행 - 알림 미허용") {
    CardCreationProcessingView(
        progress: 0.75,
        notificationsEnabled: false,
        onCancel: {}
    )
}
#endif
