import SwiftUI

struct RecapScreenshotThumbnail: View {
    let kind: CollectionKind
    var assetName: String?
    var cornerRadius: CGFloat = 5
    var hasFavoriteFold = false

    var body: some View {
        Group {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipShape(thumbnailShape)
        .clipped()
        .overlay {
            thumbnailShape
                .stroke(Color.recapGray100, lineWidth: 1)
        }
    }

    private var thumbnailShape: RecapScreenshotThumbnailShape {
        RecapScreenshotThumbnailShape(
            cornerRadius: cornerRadius,
            hasFavoriteFold: hasFavoriteFold
        )
    }

    private var placeholder: some View {
        let display = RecapPresentation.collectionDisplay(for: kind)

        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color.recapThumbnail)
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(display.dotColor.opacity(0.20))
                    .frame(height: 18)
            }
            .overlay {
                Image(systemName: display.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(display.textColor.opacity(0.55))
            }
    }
}

private struct RecapScreenshotThumbnailShape: Shape {
    let cornerRadius: CGFloat
    let hasFavoriteFold: Bool

    func path(in rect: CGRect) -> Path {
        guard hasFavoriteFold else {
            return RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .path(in: rect)
        }

        let scaleX = rect.width / 62
        let scaleY = rect.height / 80
        let radius = 5 * min(scaleX, scaleY)
        let foldTopEndX = rect.minX + (31 * scaleX)
        let foldVerticalX = rect.minX + (36 * scaleX)
        let foldBottomStartX = rect.minX + (41 * scaleX)
        let foldBottomY = rect.minY + (24 * scaleY)
        let rightFoldStartX = rect.maxX - radius
        let rightFoldBottomY = foldBottomY + radius

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: foldTopEndX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: foldVerticalX, y: rect.minY + radius),
            control: CGPoint(x: foldVerticalX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: foldVerticalX, y: foldBottomY - radius))
        path.addQuadCurve(
            to: CGPoint(x: foldBottomStartX, y: foldBottomY),
            control: CGPoint(x: foldVerticalX, y: foldBottomY)
        )
        path.addLine(to: CGPoint(x: rightFoldStartX, y: foldBottomY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rightFoldBottomY),
            control: CGPoint(x: rect.maxX, y: foldBottomY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

#Preview("스크린샷 썸네일") {
    RecapScreenshotThumbnail(
        kind: .shopping,
        assetName: SampleData.cards[0].thumbnailAssetName
    )
    .frame(width: 134, height: 85)
    .padding()
}
