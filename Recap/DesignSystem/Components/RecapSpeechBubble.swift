import SwiftUI

struct RecapSpeechBubble: View {
    let text: String
    var width: CGFloat = 143

    var body: some View {
        ZStack(alignment: .top) {
            SpeechBubbleShape()
                .fill(Color.recapBackground)
                .overlay {
                    SpeechBubbleShape()
                        .stroke(Color.recapBlue300, lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 2.77,
                    x: 0,
                    y: 0.92
                )
                .frame(width: width, height: 46)

            Text(text)
                .font(RecapFont.pretendard(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundStyle(Color.recapBlue300)
                .frame(width: width, height: 41)
        }
        .frame(width: width, height: 46)
    }
}

private struct SpeechBubbleShape: Shape {
    private enum FigmaMetric {
        static let width: CGFloat = 143
        static let height: CGFloat = 45.8837890625
        static let bodyHeight: CGFloat = 40.59354782104492
        static let cornerRadius: CGFloat = 27.677419662475586
        static let tailPolygonTop: CGFloat = 31.587013727268
        static let tailPolygonSize: CGFloat = 16.296775335231587
        static let tailCornerRadius: CGFloat = 2
    }

    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / FigmaMetric.width
        let scaleY = rect.height / FigmaMetric.height
        let bodyHeight = FigmaMetric.bodyHeight * scaleY
        let bodyBottom = rect.minY + bodyHeight
        let radius = min(
            FigmaMetric.cornerRadius * min(scaleX, scaleY),
            bodyHeight / 2,
            rect.width / 2
        )
        let tailVisibleWidth = (
            FigmaMetric.tailPolygonSize
                - (FigmaMetric.bodyHeight - FigmaMetric.tailPolygonTop)
        ) * scaleX
        let tailHalfWidth = tailVisibleWidth / 2
        let tailCornerRadius = FigmaMetric.tailCornerRadius * min(scaleX, scaleY)
        let cubicArcControl = radius * 0.552_284_749_8
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control1: CGPoint(x: rect.maxX - radius + cubicArcControl, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + radius - cubicArcControl)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyBottom - radius))
        path.addCurve(
            to: CGPoint(x: rect.maxX - radius, y: bodyBottom),
            control1: CGPoint(x: rect.maxX, y: bodyBottom - radius + cubicArcControl),
            control2: CGPoint(x: rect.maxX - radius + cubicArcControl, y: bodyBottom)
        )
        path.addLine(to: CGPoint(x: rect.midX + tailHalfWidth, y: bodyBottom))
        path.addLine(
            to: CGPoint(
                x: rect.midX + tailCornerRadius * 0.85,
                y: rect.maxY - tailCornerRadius
            )
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(
                x: rect.midX + tailCornerRadius * 0.6,
                y: rect.maxY
            )
        )
        path.addQuadCurve(
            to: CGPoint(
                x: rect.midX - tailCornerRadius * 0.85,
                y: rect.maxY - tailCornerRadius
            ),
            control: CGPoint(
                x: rect.midX - tailCornerRadius * 0.6,
                y: rect.maxY
            )
        )
        path.addLine(to: CGPoint(x: rect.midX - tailHalfWidth, y: bodyBottom))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: bodyBottom))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: bodyBottom - radius),
            control1: CGPoint(x: rect.minX + radius - cubicArcControl, y: bodyBottom),
            control2: CGPoint(x: rect.minX, y: bodyBottom - radius + cubicArcControl)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + radius - cubicArcControl),
            control2: CGPoint(x: rect.minX + radius - cubicArcControl, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

#if DEBUG
#Preview {
    RecapSpeechBubble(text: "5초만에 시작하기")
        .padding()
        .background(Color.recapBackground)
}
#endif
