import SwiftUI

struct CardExpandButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SystemUIconsExpandShape()
                .stroke(
                    RecapTheme.ColorToken.textSecondary,
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 21, height: 21)
                .background {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(CardDetailStyle.inputBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("원본 이미지 전체 보기")
    }
}

private struct SystemUIconsExpandShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 21
        let scaleY = rect.height / 21
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        var path = Path()

        path.move(to: point(18.5, 7.5))
        path.addLine(to: point(18.5, 2.5))
        path.addLine(to: point(13.5, 2.5))

        path.move(to: point(18.5, 2.5))
        path.addLine(to: point(12.5, 8.429))

        path.move(to: point(7.5, 18.5))
        path.addLine(to: point(2.5, 18.523))
        path.addLine(to: point(2.5, 13.5))

        path.move(to: point(8.5, 12.5))
        path.addLine(to: point(2.5, 18.5))

        return path
    }
}

#Preview("원본 이미지 확장 버튼") {
    CardExpandButton(action: {})
        .padding(20)
        .background(Color.gray)
}
