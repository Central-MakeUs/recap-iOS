import SwiftUI

/// 아래쪽 꼬리가 달린 온보딩 말풍선.
struct RecapSpeechBubble: View {
    /// Figma 01-01_로그인 기준 치수. 폭이 달라지면 비율로 함께 늘어난다.
    private enum FigmaMetric {
        static let width: CGFloat = 143
        static let height: CGFloat = 45.8837890625
        static let bodyHeight: CGFloat = 40.59354782104492
        static let cornerRadius: CGFloat = 27.677419662475586

        /// 꼬리는 몸통 밖으로 드러난 부분만 보인다.
        static let tailVisibleHeight = height - bodyHeight
    }

    private static let renderedHeight: CGFloat = 46

    let text: String
    var width: CGFloat = FigmaMetric.width

    var body: some View {
        ZStack(alignment: .top) {
            shape
                .fill(Color.recapBackground)
                .overlay {
                    shape.stroke(Color.recapBlue300, lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 2.77,
                    x: 0,
                    y: 0.92
                )
                .frame(width: width, height: Self.renderedHeight)

            Text(text)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapBlue300)
                .frame(width: width, height: 41)
        }
        .frame(width: width, height: Self.renderedHeight)
    }

    private var shape: SpeechBubbleShape {
        let scaleX = width / FigmaMetric.width
        let scaleY = Self.renderedHeight / FigmaMetric.height

        let tail = SpeechBubbleShape.FigmaTail.size(
            visibleHeight: FigmaMetric.tailVisibleHeight
        )

        return SpeechBubbleShape(
            tailEdge: .bottom,
            tailSize: CGSize(width: tail.width * scaleX, height: tail.height * scaleY),
            cornerRadius: FigmaMetric.cornerRadius * min(scaleX, scaleY)
        )
    }
}

#if DEBUG
#Preview {
    RecapSpeechBubble(text: "5초만에 시작하기")
        .padding()
        .background(Color.recapBackground)
}
#endif
