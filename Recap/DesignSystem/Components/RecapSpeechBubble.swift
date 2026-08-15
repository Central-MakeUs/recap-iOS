import SwiftUI

/// 아래쪽 꼬리가 달린 온보딩 말풍선.
struct RecapSpeechBubble: View {
    /// Figma 01-01_로그인 기준 치수.
    private enum Layout {
        static let width: CGFloat = 143
        static let height: CGFloat = 45.8837890625
        static let bodyHeight: CGFloat = 40.59354782104492
        static let cornerRadius: CGFloat = 27.677419662475586

        /// 꼬리는 몸통 밖으로 드러난 부분만 보인다.
        static let tailVisibleHeight = height - bodyHeight
    }

    let text: String

    var body: some View {
        SpeechBubbleShape(
            tailEdge: .bottom,
            tailSize: SpeechBubbleShape.FigmaTail.size(
                visibleHeight: Layout.tailVisibleHeight
            ),
            cornerRadius: Layout.cornerRadius
        )
        .fill(Color.recapBackground)
        .stroke(Color.recapBlue300, lineWidth: 1)
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 2.77,
            x: 0,
            y: 0.92
        )
        // 꼬리 높이만큼 아래를 비워 몸통 안에서 가운데 정렬한다.
        .overlay {
            Text(text)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapBlue300)
                .padding(.bottom, Layout.tailVisibleHeight)
        }
        .frame(width: Layout.width, height: Layout.height)
    }
}

#if DEBUG
#Preview {
    RecapSpeechBubble(text: "5초만에 시작하기")
        .padding()
        .background(Color.recapBackground)
}
#endif
