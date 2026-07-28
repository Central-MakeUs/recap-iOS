import SwiftUI

struct RecapScreenshotThumbnail: View {
    let kind: CollectionKind
    var assetName: String?
    var remoteURL: URL? = nil
    var cornerRadius: CGFloat = 5
    var hasFavoriteFold = false
    var size: CGSize? = nil
    var onRemoteLoadFailure: (URL) -> Void = { _ in }

    var body: some View {
        Group {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else if let remoteURL {
                RecapRemoteImage(
                    url: remoteURL,
                    onExpiredURL: onRemoteLoadFailure,
                    imageContent: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    },
                    loadingContent: {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.recapThumbnail)
                    },
                    failureContent: {
                        placeholder
                    }
                )
            } else {
                placeholder
            }
        }
        .frame(width: size?.width, height: size?.height)
        .clipShape(thumbnailShape)
        .clipped()
        .overlay {
            thumbnailShape
                .stroke(Color.recapGray100, lineWidth: 1)
                .padding(0.5)
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

#Preview("즐겨찾기 접힘 썸네일") {
    ZStack(alignment: .topTrailing) {
        RecapScreenshotThumbnail(
            kind: .shopping,
            assetName: SampleData.cards[2].thumbnailAssetName,
            hasFavoriteFold: true
        )
        .frame(width: 62, height: 80)

        RecapIconView(
            icon: .starEmpty,
            size: 24,
            color: Color.recapGray100
        )
    }
    .padding()
}
