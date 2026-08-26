import SwiftUI

/// 몸통과 꼬리를 하나의 `Path`로 이어 그리는 말풍선.
///
/// 몸통과 꼬리를 따로 그려 겹치면 꼬리 밑변 자리의 몸통 테두리를 흰색으로
/// 덮어 지워야 하는데, 안티에일리어싱 때문에 경계에 얇은 자국이 남는다.
/// 한 번에 이어 그리면 테두리가 끊기지 않아 그 문제가 없다.
///
/// `rect`는 꼬리까지 포함한 크기다. 몸통 높이는 `rect.height - tailSize.height`가
/// 된다. 꼬리는 가로 가운데에 붙는다.
struct SpeechBubbleShape: Shape {
    enum TailEdge {
        case top
        case bottom
    }

    /// 피그마의 말풍선 꼬리는 두 화면 모두 같은 도형이다 — 한 변 16.2968짜리
    /// 삼각형에 꼭짓점 반경 2. 몸통에 파묻힌 깊이만 달라서 드러나는 크기가 다르다.
    enum FigmaTail {
        static let tipRadius: CGFloat = 2

        /// 몸통 밖으로 드러난 높이로 꼬리 크기를 구한다.
        ///
        /// 밑변과 높이가 같은 삼각형이라 꼭짓점에서 떨어진 거리가 곧 그 지점의
        /// 너비다. 꼭짓점은 반경만큼 깎이므로 너비는 드러난 높이보다 그만큼 크다.
        static func size(visibleHeight: CGFloat) -> CGSize {
            CGSize(width: visibleHeight + tipRadius, height: visibleHeight)
        }
    }

    var tailEdge: TailEdge = .bottom
    /// 꼬리의 밑변 너비와 높이.
    var tailSize: CGSize
    var cornerRadius: CGFloat
    /// 꼬리 끝을 둥글리는 반경. 0이면 뾰족하다.
    var tailTipRadius: CGFloat = 2

    func path(in rect: CGRect) -> Path {
        let local = CGRect(origin: .zero, size: rect.size)
        var path = pathWithTailAtBottom(in: local)

        if tailEdge == .top {
            path = path.applying(
                CGAffineTransform(scaleX: 1, y: -1)
                    .concatenating(CGAffineTransform(translationX: 0, y: local.height))
            )
        }

        return path.applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }

    private func pathWithTailAtBottom(in rect: CGRect) -> Path {
        let bodyBottom = rect.maxY - tailSize.height
        let bodyHeight = bodyBottom - rect.minY
        let radius = min(cornerRadius, bodyHeight / 2, rect.width / 2)
        let tailHalfWidth = min(tailSize.width / 2, rect.width / 2 - radius)
        let tipRadius = min(tailTipRadius, tailSize.height, tailHalfWidth)
        /// 원을 베지에 곡선으로 근사할 때 쓰는 제어점 비율.
        let arcControl = radius * 0.552_284_749_8
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control1: CGPoint(x: rect.maxX - radius + arcControl, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + radius - arcControl)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyBottom - radius))
        path.addCurve(
            to: CGPoint(x: rect.maxX - radius, y: bodyBottom),
            control1: CGPoint(x: rect.maxX, y: bodyBottom - radius + arcControl),
            control2: CGPoint(x: rect.maxX - radius + arcControl, y: bodyBottom)
        )

        path.addLine(to: CGPoint(x: rect.midX + tailHalfWidth, y: bodyBottom))
        path.addLine(to: CGPoint(x: rect.midX + tipRadius * 0.85, y: rect.maxY - tipRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX + tipRadius * 0.6, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - tipRadius * 0.85, y: rect.maxY - tipRadius),
            control: CGPoint(x: rect.midX - tipRadius * 0.6, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.midX - tailHalfWidth, y: bodyBottom))

        path.addLine(to: CGPoint(x: rect.minX + radius, y: bodyBottom))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: bodyBottom - radius),
            control1: CGPoint(x: rect.minX + radius - arcControl, y: bodyBottom),
            control2: CGPoint(x: rect.minX, y: bodyBottom - radius + arcControl)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + radius - arcControl),
            control2: CGPoint(x: rect.minX + radius - arcControl, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
