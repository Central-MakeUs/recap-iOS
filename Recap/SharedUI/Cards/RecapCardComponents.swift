import SwiftUI

struct RecapScreenshotThumbnail: View {
    enum FallbackStyle {
        /// 목록 썸네일처럼 카드 자체가 캐릭터 몸이 되는 경우 눈만 표시한다.
        case character
        /// 홈·상세처럼 넓은 영역에는 눈 달린 폴더를 가운데 표시한다.
        case folderCharacter
    }

    let kind: CollectionKind
    var assetName: String?
    var remoteURL: URL? = nil
    var cornerRadius: CGFloat = 5
    var hasFavoriteFold = false
    var size: CGSize? = nil
    var fallbackStyle: FallbackStyle = .folderCharacter
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
                        fallback
                    },
                    failureContent: {
                        fallback
                    }
                )
            } else {
                fallback
            }
        }
        .frame(width: size?.width, height: size?.height)
        .clipShape(thumbnailShape)
        .clipped()
        .overlay {
            thumbnailShape
                .strokeBorder(Color.recapGray100, lineWidth: 1)
        }
    }

    private var thumbnailShape: RecapScreenshotThumbnailShape {
        RecapScreenshotThumbnailShape(
            cornerRadius: cornerRadius,
            hasFavoriteFold: hasFavoriteFold
        )
    }

    @ViewBuilder
    private var fallback: some View {
        switch fallbackStyle {
        case .character:
            Color.recapGray50
                .overlay(alignment: .bottomLeading) {
                    Image("RecapIconCharacterEyes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .padding(.leading, 7)
                        .padding(.bottom, 5)
                }
        case .folderCharacter:
            Color.recapGray50
                .overlay {
                    Image("RecapIconCharacterFolder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 21)
                }
        }
    }
}

private struct RecapScreenshotThumbnailShape: InsettableShape {
    let cornerRadius: CGFloat
    let hasFavoriteFold: Bool
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> RecapScreenshotThumbnailShape {
        var insetShape = self
        insetShape.insetAmount += amount
        return insetShape
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let insetCornerRadius = max(0, cornerRadius - insetAmount)

        guard hasFavoriteFold else {
            return RoundedRectangle(
                cornerRadius: insetCornerRadius,
                style: .continuous
            )
            .path(in: rect)
        }

        let scaleX = rect.width / 62
        let scaleY = rect.height / 80
        let radius = max(0, (5 * min(scaleX, scaleY)) - insetAmount)
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

#if DEBUG
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

#Preview("즐겨찾기 썸네일 폴백") {
    ZStack(alignment: .topTrailing) {
        RecapScreenshotThumbnail(
            kind: .shopping,
            assetName: nil,
            hasFavoriteFold: true,
            size: CGSize(width: 62, height: 80),
            fallbackStyle: .character
        )

        RecapIconView(
            icon: .star,
            size: 24,
            color: Color.recapBlue300
        )
    }
    .frame(width: 62, height: 80)
    .padding()
}
#endif
